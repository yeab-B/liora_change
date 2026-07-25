<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChallengeCategory extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'slug',
    ];

    /**
     * Starter templates curated under this category.
     */
    public function templates(): HasMany
    {
        return $this->hasMany(ChallengeTemplate::class);
    }

    /**
     * Member challenges filed under this category.
     */
    public function challenges(): HasMany
    {
        return $this->hasMany(Challenge::class);
    }
}
