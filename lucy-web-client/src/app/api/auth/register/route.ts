import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const body = await request.json();

    const backendUrl = process.env.NEXT_PUBLIC_AUTH_SERVICE_URL || 'http://127.0.0.1:5086';
    
    // According to RegisterRequest: Email, Password, Role, LanguageId, DisplayName, AvatarUrl
    // We send PascalCase keys just to be absolutely safe with .NET's model binder.
    const payload = {
      Email: body.email,
      Password: body.password,
      DisplayName: body.displayName || body.email.split('@')[0],
      Role: 'LUCY'
    };

    const response = await fetch(`${backendUrl}/api/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const data = await response.json().catch(() => null);

    if (!response.ok) {
      // Parse ASP.NET Core ValidationProblemDetails
      let errorMessage = data?.error || data?.detail || 'Registration failed';
      
      if (data?.errors && typeof data.errors === 'object') {
        // Flatten the errors object into a single string
        const errorMessages = Object.values(data.errors).flat();
        if (errorMessages.length > 0) {
          errorMessage = errorMessages[0]; // Show the first validation error
        }
      } else if (data?.title) {
        errorMessage = data.title;
      }

      return NextResponse.json(
        { error: errorMessage },
        { status: response.status }
      );
    }

    return NextResponse.json(data || { success: true });
  } catch (error) {
    console.error('Register proxy error:', error);
    return NextResponse.json(
      { error: 'Network error. Make sure backend is running.' },
      { status: 500 }
    );
  }
}
