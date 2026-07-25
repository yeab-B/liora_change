<?php
namespace App\Shared\Enums;

enum RoleName: string {
    case SuperAdmin = 'SuperAdmin';
    case Admin = 'Admin';
    case ContentManager = 'ContentManager';
    case SupportStaff = 'SupportStaff';
    case PremiumUser = 'PremiumUser';
    case RegisteredUser = 'RegisteredUser';
    case FreeUser = 'FreeUser';
    case Guest = 'Guest';
}
