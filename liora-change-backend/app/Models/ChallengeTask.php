<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChallengeTask extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $guarded = [];

    public function challenge(): BelongsTo
    {
        return $this->belongsTo(Challenge::class);
    }
}
