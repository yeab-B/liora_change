<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChallengeCategory extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $guarded = [];

    public function challenges(): HasMany
    {
        return $this->hasMany(Challenge::class, 'category_id');
    }
}
