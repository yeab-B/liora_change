<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class MotivationRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * Ownership of `challenge_id` (if provided) is checked in the
     * controller via the ChallengePolicy so a challenge belonging to
     * another user yields 403/404 rather than a validation error.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'challenge_id' => ['nullable', 'integer'],
            'context' => ['nullable', Rule::in(['morning', 'recovery', 'general'])],
        ];
    }
}
