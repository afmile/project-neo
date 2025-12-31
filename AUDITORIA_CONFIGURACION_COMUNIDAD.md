# 🔍 AUDITORÍA: PANTALLA DE CONFIGURACIÓN DE COMUNIDAD

**Fecha:** 2024  
**Objetivo:** Mapear la estructura actual de configuración de comunidad y detectar huecos para implementación de "Títulos"

---

## 📍 1. ENTRY POINT

### Pantalla Origen
**Archivo:** `lib/features/community/presentation/screens/community_home_screen.dart`  
**Líneas:** 220-266

### Flujo de Navegación
1. **Ubicación:** `CommunityHomeScreen` - AppBar (botón `Icons.more_vert`)
2. **Trigger:** Usuario toca el botón de menú (3 puntos verticales) en la esquina superior derecha
3. **Acción:** Se abre un `ModalBottomSheet` con opciones
4. **Opción disponible:** "Configuración" (única opción actual)
5. **Navegación:** Usa `context.pushNamed('community-settings', ...)`

### Ruta Definida
**Archivo:** `lib/core/router/app_router.dart`  
**Líneas:** 317-330

```dart
GoRoute(
  path: '/community/:id/settings',
  name: 'community-settings',
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) {
    final extras = state.extra as Map<String, dynamic>;
    return CommunitySettingsScreen(
      communityId: state.pathParameters['id']!,
      communityName: extras['name'] as String,
      themeColor: extras['color'] as Color,
    );
  },
)
```

**Parámetros pasados:**
- `id`: ID de la comunidad (desde path)
- `name`: Nombre de la comunidad (desde extra)
- `color`: Color del tema (desde extra)

---

## 🗺️ 2. MAPA DEL MENÚ

### Pantalla Principal
**Archivo:** `lib/features/community/presentation/screens/community_settings_screen.dart`  
**Clase:** `CommunitySettingsScreen`

### Estructura Actual

#### Sección: "PREFERENCIAS"
**Línea:** 176

**Contenido:** Un solo `Card` con switches de notificaciones

| Tile/Switch | Label Visible | Archivo/Clase | Handler | Estado | Repos/Providers | Supabase |
|------------|---------------|---------------|---------|--------|-----------------|----------|
| Master Switch | "Activar notificaciones" | `_buildSwitchTile()` (línea 251) | `_onSettingChanged('enabled', v)` | ✅ **FUNCIONAL** | `notificationSettingsProvider` | `community_members.notification_settings` |
| Chat | "Mensajes de chat" | `_buildSwitchTile()` (línea 209) | `_onSettingChanged('chat', v)` | ✅ **FUNCIONAL** | `notificationSettingsProvider` | `community_members.notification_settings` |
| Menciones | "Menciones" | `_buildSwitchTile()` (línea 215) | `_onSettingChanged('mentions', v)` | ✅ **FUNCIONAL** | `notificationSettingsProvider` | `community_members.notification_settings` |
| Anuncios | "Anuncios" | `_buildSwitchTile()` (línea 221) | `_onSettingChanged('announcements', v)` | ✅ **FUNCIONAL** | `notificationSettingsProvider` | `community_members.notification_settings` |
| Nuevos posts | "Nuevos posts" | `_buildSwitchTile()` (línea 227) | `_onSettingChanged('wall_posts', v)` | ✅ **FUNCIONAL** | `notificationSettingsProvider` | `community_members.notification_settings` |
| Reacciones | "Reacciones" | `_buildSwitchTile()` (línea 233) | `_onSettingChanged('reactions', v)` | ✅ **FUNCIONAL** | `notificationSettingsProvider` | `community_members.notification_settings` |

### Provider Utilizado
**Archivo:** `lib/features/community/presentation/screens/community_settings_screen.dart`  
**Líneas:** 15-25

```dart
final notificationSettingsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, communityId) async {
  final repository = ref.read(communityRepositoryProvider);
  final user = ref.read(currentUserProvider);
  
  if (user == null) throw Exception("User not authenticated");

  return repository.getNotificationSettings(
    communityId: communityId,
    userId: user.id,
  );
});
```

### Repository Methods
**Archivo:** `lib/features/community/data/repositories/community_repository.dart`  
**Métodos:**
- `getNotificationSettings()` - Líneas 469-505
- `updateNotificationSettings()` - Líneas 507-547

**Tabla Supabase:** `community_members.notification_settings` (JSONB)

---

## 📦 3. INVENTARIO DE MÓDULOS EXISTENTES

### 3.1 Gestión de Miembros

#### Pantalla de Miembros
**Archivo:** `lib/features/community/presentation/screens/community_members_screen.dart`  
**Clase:** `CommunityMembersScreen`

**Funcionalidad:**
- ✅ Muestra lista de miembros de la comunidad
- ✅ Filtra por roles (owner, leader, agent)
- ✅ Muestra miembros online
- ✅ Muestra miembros recientes
- ❌ **NO tiene gestión de roles** (solo visualización)
- ❌ **NO permite asignar/remover roles**

#### Provider de Miembros
**Archivo:** `lib/features/community/presentation/providers/community_members_provider.dart`  
**Provider:** `communityMembersProvider`

**Tabla Supabase:** `community_members`  
**Query:** JOIN con `users_global` para obtener datos de perfil

**Roles soportados:**
- `owner` → "Dueño"
- `agent` → "Agente"
- `leader` → "Líder"
- `member` → "Miembro" (default)

### 3.2 Roles (Leader/Mod)

#### Schema de Roles
**Archivo:** `supabase/schema.sql`  
**Líneas:** 203-230

**Tipo ENUM:** `membership_role`
```sql
CREATE TYPE membership_role AS ENUM ('owner', 'agent', 'leader', 'curator', 'member');
```

**Tabla:** `community_members.role`

**Estado:**
- ✅ Schema existe en DB
- ✅ Provider puede leer roles
- ❌ **NO hay UI para gestionar roles**
- ❌ **NO hay repositorio methods para cambiar roles**
- ❌ **NO hay permisos/RLS para asignar roles**

### 3.3 Providers/Repos de Comunidad

#### CommunityRepository
**Archivo:** `lib/features/community/data/repositories/community_repository.dart`

**Métodos disponibles:**
- `getUserCommunities()`
- `discoverCommunities()`
- `getCommunityById()`
- `getCommunityBySlug()`
- `createCommunity()`
- `updateCommunity()`
- `joinCommunity()`
- `leaveCommunity()`
- `updateLocalProfile()`
- `getNotificationSettings()` ✅
- `updateNotificationSettings()` ✅
- `fetchWallPostsPaginated()`
- `createWallPost()`
- `toggleWallPostLike()`
- `deleteWallPost()`

**Métodos FALTANTES para gestión:**
- ❌ `updateMemberRole()` - No existe
- ❌ `assignTitle()` - No existe (pero existe en TitlesRepository)
- ❌ `removeMember()` - No existe
- ❌ `banMember()` - No existe

#### CommunityProviders
**Archivo:** `lib/features/community/presentation/providers/community_providers.dart`

**Providers disponibles:**
- `communityRepositoryProvider`
- `communityProvider` (single community)
- `userCommunitiesProvider`
- `discoverCommunitiesProvider`

### 3.4 Títulos (Titles)

#### Schema de Títulos
**Archivo:** `supabase/migrations/026_community_titles.sql`

**Tablas:**
1. `community_titles` - Definición de títulos por comunidad
2. `community_member_titles` - Asignación de títulos a miembros

**Campos clave:**
- `community_titles.name` - Nombre del título
- `community_titles.style` - JSONB con `{bg, fg, icon}`
- `community_titles.priority` - Orden de visualización
- `community_member_titles.member_user_id` - Usuario asignado
- `community_member_titles.title_id` - Título asignado
- `community_member_titles.expires_at` - Fecha de expiración (opcional)

**RLS Policies:**
- ✅ SELECT: Miembros pueden ver títulos
- ✅ INSERT/UPDATE/DELETE: Solo leaders/curators/mods pueden gestionar

#### Repository de Títulos
**Archivo:** `lib/features/community/data/repositories/titles_repository.dart`  
**Clase:** `TitlesRepository`

**Métodos disponibles:**
- ✅ `fetchUserTitles()` - Obtener títulos de un usuario
- ✅ `fetchCommunityTitles()` - Obtener todos los títulos de una comunidad
- ✅ `assignTitle()` - Asignar título a usuario
- ✅ `removeTitle()` - Remover asignación
- ✅ `createTitle()` - Crear nuevo título
- ✅ `updateTitle()` - Actualizar título
- ✅ `deactivateTitle()` - Desactivar título

#### Providers de Títulos
**Archivo:** `lib/features/community/presentation/providers/user_titles_provider.dart`

**Providers:**
- ✅ `titlesRepositoryProvider`
- ✅ `userTitlesProvider` - Títulos de un usuario específico
- ✅ `communityTitlesProvider` - Todos los títulos de una comunidad

#### UI de Títulos
**Widgets existentes:**
1. **ProfileTitlesChips**
   - **Archivo:** `lib/features/community/presentation/widgets/profile_titles_chips.dart`
   - **Uso:** Muestra chips de títulos en perfiles
   - **Estado:** ✅ Funcional

2. **ProfileHeaderSection**
   - **Archivo:** `lib/features/community/presentation/widgets/profile_header_section.dart`
   - **Líneas:** 152-179
   - **Uso:** Muestra títulos en header de perfil
   - **Estado:** ✅ Funcional

3. **UserTitleTagWidget**
   - **Archivo:** `lib/features/community/presentation/widgets/user_title_tag_widget.dart`
   - **Estado:** ✅ Funcional

**Pantallas que muestran títulos:**
- ✅ `PublicUserProfileScreen` - Muestra títulos en perfil público
- ✅ `CommunityUserProfileScreen` - Muestra títulos en perfil de comunidad

**Pantallas FALTANTES:**
- ❌ **NO hay pantalla de gestión de títulos** (crear/editar/eliminar títulos)
- ❌ **NO hay pantalla de asignación de títulos a miembros**

#### Entities de Títulos
**Archivos:**
- `lib/features/community/domain/entities/community_title.dart`
- `lib/features/community/domain/entities/member_title.dart`
- `lib/features/community/domain/entities/user_title_tag.dart`

**Estado:** ✅ Todas las entidades están definidas

---

## 🕳️ 4. HUECOS DETECTADOS

### 4.1 En la Pantalla de Configuración Actual

**Problemas:**
1. ❌ **Solo tiene notificaciones** - No hay otras opciones de configuración
2. ❌ **No hay secciones adicionales** - Solo "PREFERENCIAS"
3. ❌ **No hay gestión de roles** - No se puede cambiar roles de miembros
4. ❌ **No hay gestión de títulos** - No se puede crear/editar/asignar títulos
5. ❌ **No hay gestión de miembros** - No se puede banear/remover miembros
6. ❌ **No hay configuración de comunidad** - No se puede editar nombre/descripción/tema

### 4.2 Funcionalidades "Fake" o Placeholder

**No hay funcionalidades fake detectadas** - Todo lo que está implementado funciona correctamente.

**Sin embargo:**
- El menú de `CommunityHomeScreen` tiene un comentario: `// More options can form here` (línea 259)
- Esto sugiere que se planeaba agregar más opciones pero no se implementaron

### 4.3 Módulos Incompletos

1. **Gestión de Roles:**
   - ✅ Schema existe
   - ✅ Provider puede leer roles
   - ❌ No hay UI para cambiar roles
   - ❌ No hay método en repository para cambiar roles
   - ❌ No hay validación de permisos para cambiar roles

2. **Gestión de Títulos:**
   - ✅ Schema completo
   - ✅ Repository completo
   - ✅ Providers completos
   - ✅ UI de visualización completa
   - ❌ **NO hay UI de gestión** (crear/editar/eliminar títulos)
   - ❌ **NO hay UI de asignación** (asignar títulos a miembros)

3. **Gestión de Miembros:**
   - ✅ Visualización de miembros
   - ❌ No hay banear/remover miembros
   - ❌ No hay cambiar roles
   - ❌ No hay asignar títulos desde la lista de miembros

### 4.4 Neo Studio (Panel de Administración)

**Archivo:** `lib/features/community/presentation/screens/community_studio_screen.dart`

**Estado:** ⚠️ **EXISTE pero no se revisó en detalle**

**Acceso:** Solo para owners (botón visible solo si es owner)  
**Ubicación:** Botón en `CommunityHomeScreen` (línea 195-203)

**Nota:** Esta pantalla podría ser el lugar correcto para gestión avanzada, pero no está en el scope de esta auditoría.

---

## 💡 5. PROPUESTA: DÓNDE AGREGAR TILE "TÍTULOS"

### 5.1 Ubicación Exacta

**Archivo:** `lib/features/community/presentation/screens/community_settings_screen.dart`  
**Método:** `_buildContent()`  
**Línea aproximada:** Después de la línea 246 (después del Card de notificaciones)

### 5.2 Estructura Sugerida

```dart
Widget _buildContent() {
  if (_localSettings == null) return const SizedBox.shrink();

  final enabled = _localSettings!['enabled'] == true;

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Sección existente: Notificaciones
      _buildSectionHeader('Preferencias'),
      const SizedBox(height: 8),
      Card(...), // Card de notificaciones actual
      
      const SizedBox(height: 32), // Espaciado
      
      // NUEVA SECCIÓN: Gestión
      _buildSectionHeader('Gestión'),
      const SizedBox(height: 8),
      
      // NUEVO TILE: Títulos
      _buildSettingsTile(
        title: 'Títulos',
        subtitle: 'Gestiona los títulos de la comunidad',
        icon: Icons.stars,
        onTap: () {
          // Navegar a pantalla de gestión de títulos
          context.pushNamed(
            'community-titles-management',
            pathParameters: {'id': widget.communityId},
            extra: {
              'name': widget.communityName,
              'color': widget.themeColor,
            },
          );
        },
      ),
      
      // Futuros tiles pueden ir aquí:
      // - Gestión de miembros
      // - Roles y permisos
      // - Configuración de comunidad
    ],
  );
}
```

### 5.3 Ruta Destino Sugerida

**Ruta:** `/community/:id/settings/titles`  
**Nombre:** `community-titles-management`

**Parámetros:**
- `id`: ID de la comunidad (path parameter)
- `name`: Nombre de la comunidad (extra)
- `color`: Color del tema (extra)

**Pantalla destino:** Nueva pantalla `CommunityTitlesManagementScreen`

### 5.4 Consideraciones

1. **Permisos:** Solo leaders/curators/mods deberían ver este tile
   - Verificar rol del usuario antes de mostrar
   - Usar `myLocalIdentityProvider` para obtener rol

2. **Visibilidad condicional:**
   ```dart
   if (userRole in ['owner', 'agent', 'leader', 'curator']) {
     // Mostrar tile de Títulos
   }
   ```

3. **No duplicar settings:**
   - Este tile debe estar SOLO en `CommunitySettingsScreen`
   - No crear otra pantalla de "settings" separada
   - Usar la misma estructura de secciones que ya existe

4. **Consistencia visual:**
   - Usar el mismo estilo de `Card` que las notificaciones
   - Usar `_buildSectionHeader()` para el título de sección
   - Mantener el mismo padding y espaciado

---

## 📊 6. RESUMEN EJECUTIVO

### Estado Actual
- ✅ **Entry point:** Funcional desde `CommunityHomeScreen`
- ✅ **Ruta:** Configurada correctamente en router
- ✅ **Pantalla base:** Implementada y funcional
- ✅ **Notificaciones:** Completamente funcional
- ❌ **Gestión:** No hay opciones de gestión disponibles

### Módulos Relacionados
- ✅ **Miembros:** Visualización funcional, gestión ausente
- ✅ **Roles:** Schema completo, UI ausente
- ✅ **Títulos:** Backend completo, UI de gestión ausente

### Huecos Principales
1. No hay UI para gestionar títulos (aunque el backend está completo)
2. No hay UI para gestionar roles
3. No hay UI para gestionar miembros (banear/remover)
4. La pantalla de configuración solo tiene notificaciones

### Propuesta
- Agregar tile "Títulos" en `CommunitySettingsScreen` después del Card de notificaciones
- Crear nueva sección "Gestión" para agrupar opciones administrativas
- Ruta destino: `/community/:id/settings/titles`
- Verificar permisos antes de mostrar el tile

---

## ✅ CHECKLIST PARA IMPLEMENTACIÓN

- [ ] Agregar sección "Gestión" en `_buildContent()`
- [ ] Crear método `_buildSettingsTile()` para tiles navegables
- [ ] Agregar tile "Títulos" con navegación a pantalla de gestión
- [ ] Verificar permisos (solo leaders/mods pueden ver)
- [ ] Crear ruta `community-titles-management` en router
- [ ] Crear pantalla `CommunityTitlesManagementScreen`
- [ ] Implementar UI de gestión de títulos (CRUD)
- [ ] Implementar UI de asignación de títulos a miembros
- [ ] Probar flujo completo

---

**Fin del Reporte**

