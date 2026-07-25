<?php
namespace App\Shared\Enums;

enum PermissionName: string {
    case ManageUsers = 'manage users';
    case ManageRoles = 'manage roles';
    case ManageSettings = 'manage settings';
}
