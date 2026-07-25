<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Challenge extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'category_id',
        'title',
        'description',
        'status',
        'difficulty',
        'visibility',
        'start_date',
        'end_date',
        'duration_days',
        'current_streak',
        'longest_streak',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'duration_days' => 'integer',
        'current_streak' => 'integer',
        'longest_streak' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * The curated category this challenge falls under, if any (added by
     * Issue #3, which also adds the real FK constraint on `category_id`).
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(ChallengeCategory::class);
    }

    /**
     * Declared ahead of Issue #4 (Check-ins API), which creates the CheckIn
     * model/table. Safe to declare now: PHP only resolves `CheckIn::class`
     * when this method is actually invoked, not when the class is loaded.
     */
    public function checkIns(): HasMany
    {
        return $this->hasMany(CheckIn::class);
    }
}
