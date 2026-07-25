<?php

namespace App\Shared\Enums;

enum ChallengeDifficulty: string
{
    case Beginner = 'beginner';
    case Easy = 'easy';
    case Medium = 'medium';
    case Hard = 'hard';
    case Expert = 'expert';
}
