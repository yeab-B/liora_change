<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class ChatRequest extends FormRequest
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
     * Ownership of `session_id`/`challenge_id` (if provided) is checked in
     * the controller via policies so a resource belonging to another user
     * yields 403/404 rather than a validation error.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'message' => ['required', 'string', 'max:1000'],
            'session_id' => ['nullable', 'integer'],
            'challenge_id' => ['nullable', 'integer'],
        ];
    }
}
