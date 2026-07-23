import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const body = await request.json();

    // Target the consolidated LUCY backend on port 3001
    const backendUrl = process.env.NEXT_PUBLIC_AUTH_SERVICE_URL || 'http://127.0.0.1:3001';
    
    const email = body.email || body.Email;
    const password = body.password || body.Password;

    const response = await fetch(`${backendUrl}/api/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password }),
    });

    const data = await response.json().catch(() => null);

    if (!response.ok) {
      return NextResponse.json(
        { error: data?.error || data?.detail || 'Authentication failed. Please check your credentials.' },
        { status: response.status || 401 }
      );
    }

    const res = NextResponse.json(data);
    
    const tokenToSet = data?.token || data?.accessToken || data?.AccessToken;
    
    if (tokenToSet) {
      res.cookies.set('lucy_token', tokenToSet, {
        httpOnly: false,
        secure: false,
        sameSite: 'lax',
        path: '/',
        maxAge: 7 * 24 * 60 * 60, // 7 days
      });
    }

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
        secure: false,
        sameSite: 'lax',
        path: '/',
        maxAge: 7 * 24 * 60 * 60,
      });
    }

    return res;
  } catch (error) {
    console.error('Login proxy error:', error);
    return NextResponse.json(
      { error: 'Internal Server Error. Please make sure LUCY Backend on port 3001 is running.' },
      { status: 500 }
    );
  }
}
