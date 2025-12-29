/// Project Neo - Bug Report Repository
///
/// Repository for submitting bug reports to Supabase.
library;

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';
import '../supabase/schema/schema.dart';

class BugReportRepository {
  final SupabaseClient _supabase;
  
  BugReportRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;
  
  /// Submit a bug report with guaranteed context
  /// 
  /// Returns Right(sentryEventId) on success, Left(error message) on failure
  Future<Either<String, String?>> submitBugReport({
    required String description,
    required String route,
    String? communityId,
    String? feature,
    String? sentryEventId,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // Get user ID (nullable for logged out users)
      final userId = _supabase.auth.currentUser?.id;
      
      // Get app version and build number
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;
      
      // Get device info (without sensitive PII)
      final deviceInfo = await _getDeviceInfo();
      
      // Prepare bug report data with guaranteed context
      final reportData = {
        BugReportsSchema.userId: userId,
        BugReportsSchema.communityId: communityId,
        BugReportsSchema.route: route,
        BugReportsSchema.description: description,
        BugReportsSchema.appVersion: appVersion,
        BugReportsSchema.buildNumber: buildNumber,
        BugReportsSchema.platform: EnvConfig.platformName,
        BugReportsSchema.deviceInfo: deviceInfo,
        BugReportsSchema.sentryEventId: sentryEventId,
        BugReportsSchema.feature: feature,
        BugReportsSchema.extra: extraData ?? {},
      };
      
      // Insert bug report (only INSERT is allowed per RLS)
      await _supabase
          .from(BugReportsSchema.tableName)
          .insert(reportData);
      
      return Right(sentryEventId);
    } on PostgrestException catch (e) {
      return Left('Error al enviar reporte: ${e.message}');
    } catch (e) {
      return Left('Error inesperado: $e');
    }
  }
  
  /// Get device information without sensitive PII
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    
    try {
      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        return {
          'browser': webInfo.browserName.toString(),
          'user_agent': webInfo.userAgent ?? 'unknown',
        };
      }
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return {
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'android_version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'is_physical_device': androidInfo.isPhysicalDevice,
        };
      }
      
      if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return {
          'model': iosInfo.model,
          'name': iosInfo.name,
          'system_version': iosInfo.systemVersion,
          'is_physical_device': iosInfo.isPhysicalDevice,
        };
      }
      
      if (Platform.isMacOS) {
        final macOsInfo = await deviceInfoPlugin.macOsInfo;
        return {
          'model': macOsInfo.model,
          'os_release': macOsInfo.osRelease,
        };
      }
      
      if (Platform.isWindows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        return {
          'computer_name': windowsInfo.computerName,
          'number_of_cores': windowsInfo.numberOfCores,
          'system_memory': windowsInfo.systemMemoryInMegabytes,
        };
      }
      
      if (Platform.isLinux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        return {
          'name': linuxInfo.name,
          'version': linuxInfo.version,
        };
      }
      
      return {'platform': EnvConfig.platformName};
    } catch (e) {
      // If device info fails, return minimal info
      return {'platform': EnvConfig.platformName, 'error': 'Failed to get device info'};
    }
  }
}
