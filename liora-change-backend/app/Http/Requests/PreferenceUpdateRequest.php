<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class PreferenceUpdateRequest extends FormRequest
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
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'notifications_enabled' => ['nullable', 'boolean'],
            'dark_mode' => ['nullable', 'boolean'],
            'weekly_reports' => ['nullable', 'boolean'],
            'reminder_time' => ['nullable', 'string'],
            'measurement_units' => ['nullable', 'string', 'in:metric,imperial'],
            'theme' => ['nullable', 'string'],
            'privacy_settings' => ['nullable', 'array'],
        ];
    }
}
