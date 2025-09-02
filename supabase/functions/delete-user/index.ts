import { createClient } from '@supabase/supabase-js'
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey',
      },
    })
  }

  try {
    // 1. Cria um cliente Supabase com permissões de administrador.
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 2. Pega o token de autenticação do header da requisição.
    const authorization = req.headers.get('Authorization')!;
    const { data: { user } } = await supabaseAdmin.auth.getUser(authorization.replace('Bearer ', ''));

    if (!user) {
      throw new Error("User not found.");
    }

    // 3. Deleta o registro correspondente na tabela 'profiles'.
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .delete()
      .eq('id', user.id);

    if (profileError) {
      // Se não encontrar um perfil, pode ser ok, mas um erro real deve ser lançado.
      console.warn(`Could not delete profile for user ${user.id}:`, profileError.message);
      // Dependendo da sua lógica, você pode querer lançar o erro aqui
      // throw new Error(`Failed to delete profile: ${profileError.message}`);
    }

    // 4. Usa o cliente administrador para deletar o usuário pelo ID.
    const { error: authError } = await supabaseAdmin.auth.admin.deleteUser(user.id);

    if (authError) {
      throw authError;
    }

    // 5. Retorna uma resposta de sucesso.
    return new Response(JSON.stringify({ message: `User ${user.id} and profile deleted.` }), {
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
       },
      status: 200,
    });

  } catch (err) {
    console.error('Error deleting user:', err);
    const errorMessage = err instanceof Error ? err.message : 'An unknown error occurred.';
    return new Response(JSON.stringify({ error: errorMessage }), {
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
       },
      status: 500, // Internal Server Error é mais apropriado
    });
  }
})
