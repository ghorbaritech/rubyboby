import 'package:supabase_flutter/supabase_flutter.dart';
import 'persona_state.dart';
import 'auth_service.dart';

class PersonaService {
  static Future<bool> savePersona(CustomPersona persona) async {
    try {
      final Map<String, dynamic> data = persona.toJson();
      final Map<String, dynamic> dbData = {
        'id': data['id'],
        'user_email': AuthService.currentUserEmail,
        'name': data['name'],
        'traits': data['traits'],
        'age': data['age'],
        'gender': data['gender'],
        'color_value': data['colorValue'],
        'language': data['language'],
        'role': data['role'],
        'face_zoom': data['faceZoom'],
        'face_y_offset': data['faceYOffset'],
        'image_base64': data['imageBase64'],
      };

      // Perform an upsert in Supabase (insert or update on primary key conflict)
      await Supabase.instance.client
          .from('personas')
          .upsert(dbData);
      return true;
    } catch (e) {
      print('Supabase error saving persona: $e');
      return false;
    }
  }

  static Future<List<dynamic>?> getPersonas() async {
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('personas')
          .select()
          .eq('user_email', AuthService.currentUserEmail);

      // Map snake_case database columns back to camelCase JSON formats expected by CustomPersona.fromJson
      return response.map((row) => {
        'id': row['id'],
        'name': row['name'],
        'traits': row['traits'],
        'age': row['age'],
        'gender': row['gender'],
        'colorValue': row['color_value'],
        'language': row['language'],
        'role': row['role'],
        'faceZoom': row['face_zoom'],
        'faceYOffset': row['face_y_offset'],
        'imageBase64': row['image_base64'],
      }).toList();
    } catch (e) {
      print('Supabase error fetching personas: $e');
    }
    return null;
  }

  static Future<bool> deletePersona(String id) async {
    try {
      await Supabase.instance.client
          .from('personas')
          .delete()
          .eq('id', id)
          .eq('user_email', AuthService.currentUserEmail);
      return true;
    } catch (e) {
      print('Supabase error deleting persona: $e');
      return false;
    }
  }
}
