<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Challenge extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $guarded = [];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(ChallengeCategory::class);
    }

    public function tasks(): HasMany
    {
        return $this->hasMany(ChallengeTask::class);
    }

    public function schedule(): HasOne
    {
        return $this->hasOne(ChallengeSchedule::class);
    }

    public function progress(): HasOne
    {
        return $this->hasOne(ChallengeProgress::class);
    }

    public function logs(): HasMany
    {
        return $this->hasMany(ChallengeLog::class);
    }
}
