import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  
  // Public paths that do not require authentication
  const isPublicPath = pathname === '/login' || pathname === '/register' || pathname.startsWith('/_next') || pathname.startsWith('/api/');

  // Get the token from cookies
  const token = request.cookies.get('lucy_token')?.value;

  if (!isPublicPath && !token) {
    // If not public path and no token, redirect to login
    const loginUrl = new URL('/login', request.url);
    return NextResponse.redirect(loginUrl);
  }

  if ((pathname === '/login' || pathname === '/register') && token) {
    // If trying to access login/register but already authenticated, redirect to home/dashboard
    const dashboardUrl = new URL('/', request.url);
    return NextResponse.redirect(dashboardUrl);
  }

  return NextResponse.next();
}

export const config = {
  // Apply middleware to all routes except api, _next/static, _next/image, favicon.ico
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
