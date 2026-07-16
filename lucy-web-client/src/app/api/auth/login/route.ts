import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const body = await request.json();

    // Call the .NET backend Auth Service
    // Adjust the URL if your backend is hosted elsewhere
    const backendUrl = process.env.NEXT_PUBLIC_AUTH_SERVICE_URL || 'http://127.0.0.1:5086';
    
    const response = await fetch(`${backendUrl}/api/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        Email: body.email,
        Password: body.password,
      }),
    });

    const data = await response.json().catch(() => null);

    if (!response.ok) {
      return NextResponse.json(
        { error: data?.error || data?.detail || data?.title || 'Authentication failed. Please check your credentials.' },
        { status: response.status }
      );
    }

    // On success, we set the JWT token as an HTTP-only cookie
    const res = NextResponse.json(data);
    
    const tokenToSet = data?.accessToken || data?.AccessToken || data?.token;
    
    if (tokenToSet) {
      res.cookies.set('lucy_token', tokenToSet, {
        httpOnly: false,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        path: '/',
        maxAge: 7 * 24 * 60 * 60, // 7 days
      });
    }

    // Store user info in a readable cookie for the frontend
    const user = data?.user || data?.User;
    if (user) {
      const userInfo = JSON.stringify({
        id: user.id || user.Id,
        email: user.email || user.Email,
        displayName: user.displayName || user.DisplayName,
        avatarUrl: user.avatarUrl || user.AvatarUrl,
        role: user.role || user.Role,
      });
      res.cookies.set('lucy_user', userInfo, {
        httpOnly: false,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        path: '/',
        maxAge: 7 * 24 * 60 * 60,
      });
    }

    return res;
  } catch (error) {
    console.error('Login proxy error:', error);
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    );
  }
}
