import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const body = await request.json();

    const backendUrl = process.env.NEXT_PUBLIC_AUTH_SERVICE_URL || 'http://127.0.0.1:3001';
    
    const payload = {
      email: body.email || body.Email,
      password: body.password || body.Password,
      displayName: body.displayName || body.DisplayName || body.email?.split('@')[0],
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
      return NextResponse.json(
        { error: data?.error || 'Registration failed.' },
        { status: response.status || 400 }
      );
    }

    const res = NextResponse.json(data || { success: true });

    if (data?.token) {
      res.cookies.set('lucy_token', data.token, {
        httpOnly: false,
        secure: false,
        sameSite: 'lax',
        path: '/',
        maxAge: 7 * 24 * 60 * 60,
      });
    }

    if (data?.user) {
      res.cookies.set('lucy_user', JSON.stringify(data.user), {
        httpOnly: false,
        secure: false,
        sameSite: 'lax',
        path: '/',
        maxAge: 7 * 24 * 60 * 60,
      });
    }

    return res;
  } catch (error) {
    console.error('Register proxy error:', error);
    return NextResponse.json(
      { error: 'Network error. Make sure LUCY Backend on port 3001 is running.' },
      { status: 500 }
    );
  }
}
