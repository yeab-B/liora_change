<?php
namespace App\Shared\Enums;

enum AccountStatus: string {
    case Active = 'active';
    case Inactive = 'inactive';
    case Suspended = 'suspended';
    case Blocked = 'blocked';
    case Deleted = 'deleted';
    case PendingVerification = 'pending_verification';

    public function isAccessible(): bool {
        return $this === self::Active;
    }
}
