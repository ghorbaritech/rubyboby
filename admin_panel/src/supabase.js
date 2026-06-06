import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://wvervucbmsgdmryftsgf.supabase.co';
const supabaseAnonKey = 'sb_publishable_OO1WqQZ3P5xEsIgQ4eMbmQ_MJUgzCWI';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
