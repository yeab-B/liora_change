<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

class StoreCheckInRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Default `check_in_date` to "today" in the authenticated user's
     * timezone (fallback 'UTC') when the client doesn't send one.
     */
    protected function prepareForValidation(): void
    {
        if (! $this->filled('check_in_date')) {
            $timezone = $this->user()?->timezone ?: 'UTC';

            $this->merge([
                'check_in_date' => Carbon::now($timezone)->toDateString(),
            ]);
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
            'status' => ['required', Rule::in(['completed', 'skipped'])],
            'note' => ['nullable', 'string', 'max:1000'],
            'mood' => ['nullable', 'integer', 'min:1', 'max:5'],
            'energy' => ['nullable', 'integer', 'min:1', 'max:5'],
            'check_in_date' => ['nullable', 'date'],
        ];
    }
}
