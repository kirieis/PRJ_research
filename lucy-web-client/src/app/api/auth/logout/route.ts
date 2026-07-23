import { NextResponse } from 'next/server';

export async function POST() {
  const res = NextResponse.json({ success: true });
  
  // Xóa cookie thông qua server-side để đảm bảo hoạt động trên ngrok/https
  res.cookies.set('lucy_token', '', { maxAge: 0, path: '/' });
  res.cookies.set('lucy_user', '', { maxAge: 0, path: '/' });
  
  return res;
}
