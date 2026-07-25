<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserPreference extends Model
{
    protected $fillable = [
        'user_id',
        'notifications_enabled',
        'dark_mode',
        'weekly_reports',
        'reminder_time',
        'measurement_units',
        'theme',
        'privacy_settings',
    ];

    protected $casts = [
        'notifications_enabled' => 'boolean',
        'dark_mode' => 'boolean',
        'weekly_reports' => 'boolean',
        'privacy_settings' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
