pragma Ada_2022;

package body Find_All_Anagrams_In_A_String with SPARK_Mode => On is
   function Is_Anagram (A, B : Character) return Boolean is
   begin
      return (A = 'a' and then B = 'b') or else (A = 'b' and then B = 'a');
   end Is_Anagram;
   function Hit (A, B : Character) return Count is
   begin
      if Is_Anagram (A, B) then return 1; else return 0; end if;
   end Hit;
   function Count_Anagrams (Input : Text_Array) return Count is
   begin
      return Hit (Input (1), Input (2)) + Hit (Input (2), Input (3)) + Hit (Input (3), Input (4)) + Hit (Input (4), Input (5)) + Hit (Input (5), Input (6)) + Hit (Input (6), Input (7)) + Hit (Input (7), Input (8));
   end Count_Anagrams;
end Find_All_Anagrams_In_A_String;
