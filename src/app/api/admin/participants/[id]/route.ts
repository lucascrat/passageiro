import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';

// GET /api/admin/participants/[id] - Buscar participante por ID
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const resolved = await params;
  const participantId = resolved.id;

  try {
    if (!participantId) {
      return NextResponse.json(
        { error: 'Participant ID is required' },
        { status: 400 }
      );
    }

    const { data: participant, error } = await supabaseAdmin
      .from('participants')
      .select('id, name, phone, pix_key, email, game_id')
      .eq('id', participantId)
      .single();

    if (error || !participant) {
      return NextResponse.json(
        { error: 'Participant not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({ participant });
  } catch (err) {
    console.error('GET /api/admin/participants/[id] error:', err);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}