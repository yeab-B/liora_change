<?php

namespace App\Shared\Enums;

enum ChallengeStatus: string
{
    case Draft = 'draft';
    case Ready = 'ready';
    case Active = 'active';
    case Paused = 'paused';
    case Completed = 'completed';
    case Archived = 'archived';
    case Cancelled = 'cancelled';
}
