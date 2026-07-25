<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use App\Shared\Enums\RoleName;
use App\Shared\Enums\PermissionName;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Permissions
        foreach (PermissionName::cases() as $permission) {
            Permission::firstOrCreate(['name' => $permission->value]);
        }

        // Roles
        foreach (RoleName::cases() as $role) {
            Role::firstOrCreate(['name' => $role->value]);
        }

        // Assign all permissions to SuperAdmin
        $superAdminRole = Role::findByName(RoleName::SuperAdmin->value);
        $superAdminRole->syncPermissions(Permission::all());

        // Create Default Admin User
        $admin = User::firstOrCreate([
            'email' => 'admin@liorachange.com'
        ], [
            'name' => 'Super Admin',
            'password' => bcrypt('password'),
            'status' => 'active',
        ]);
        $admin->assignRole(RoleName::SuperAdmin->value);
        $admin->profile()->create(['first_name' => 'Super', 'last_name' => 'Admin']);
        $admin->preferences()->create();
    }
}
