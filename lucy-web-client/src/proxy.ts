import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export default function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  
  // Get the token from cookies
  const token = request.cookies.get('lucy_token')?.value;

  // If user is already authenticated and tries to open login or register, redirect to home
  if ((pathname === '/login' || pathname === '/register') && token) {
    const dashboardUrl = new URL('/', request.url);
    return NextResponse.redirect(dashboardUrl);
  }

  // Allow full public access to homepage, rooms, wallet, APIs so any shared Ngrok link works instantly!
  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
