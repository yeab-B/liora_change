<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserProfile extends Model
{
    protected $fillable = [
        'user_id',
        'first_name',
        'last_name',
        'phone',
        'country_id',
        'language_id',
        'timezone',
        'date_format',
        'biography',
        'birth_date',
        'gender',
        'occupation',
        'personal_goals',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
