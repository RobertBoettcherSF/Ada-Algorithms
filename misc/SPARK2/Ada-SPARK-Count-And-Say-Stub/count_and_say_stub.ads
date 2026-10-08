pragma Ada_2022;

--  Count-and-say sequence (LeetCode 38): term 1 is "1", term K + 1 reads
--  term K aloud ("1211" -> one 1, one 2, two 1s -> "111221").
--  Generalised from the old stub (terms 1 .. 5 in a 12-character field)
--  to any term whose text fits in Max_Text characters.
package Count_And_Say_Stub with SPARK_Mode => On is
   Max_Text : constant := 10_000;   --  term 33 has 9_898 characters
   subtype Text_Index is Positive range 1 .. Max_Text;
   type Text_Buffer is array (Text_Index) of Character;

   --  Writes term Number into Text (1 .. Last). Ok is False (and Last 0)
   --  if some term on the way would not fit in Max_Text characters.
   procedure Describe (Number : Positive; Text : out Text_Buffer;
                       Last : out Natural; Ok : out Boolean)
     with Global => null,
          Post   => Last <= Max_Text
                    and then (if Ok then Last >= 1 else Last = 0)
                    and then (for all I in 1 .. Last => Text (I) in '1' .. '9')
                    and then (if Number = 1 then Ok and then Last = 1
                                                and then Text (1) = '1');
end Count_And_Say_Stub;
