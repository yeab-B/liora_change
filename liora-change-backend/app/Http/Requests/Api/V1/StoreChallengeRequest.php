<?php

namespace App\Http\Requests\Api\V1;

use App\Shared\Enums\ChallengeDifficulty;
use App\Shared\Enums\ChallengeVisibility;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreChallengeRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Normalize the legacy `difficulty_score` field into `difficulty` before
     * validation runs, so older clients can send either name without the
     * API contract having two sources of truth.
     */
    protected function prepareForValidation(): void
    {
        if ($this->filled('difficulty_score') && ! $this->filled('difficulty')) {
            $this->merge(['difficulty' => $this->input('difficulty_score')]);
        }
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'difficulty' => ['nullable', Rule::enum(ChallengeDifficulty::class)],
            'visibility' => ['nullable', Rule::enum(ChallengeVisibility::class)],
            'duration_days' => ['nullable', 'integer', 'min:1', 'max:90'],
            'category_id' => ['nullable', 'integer'],
        ];
    }
}
