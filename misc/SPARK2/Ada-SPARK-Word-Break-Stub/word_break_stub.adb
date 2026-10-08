pragma Ada_2022;
package body Word_Break_Stub with SPARK_Mode => On is
   function Can_Break (Text : Letters) return Boolean is
      -- The bounded dictionary contains AB, BA, ABA, and BAB.
      Pair_12 : constant Boolean := Text (1) /= Text (2);
      Pair_34 : constant Boolean := Text (3) /= Text (4);
      Pair_56 : constant Boolean := Text (5) /= Text (6);
      Triple_123 : constant Boolean :=
        Text (1) = Text (3) and Text (1) /= Text (2);
      Triple_456 : constant Boolean :=
        Text (4) = Text (6) and Text (4) /= Text (5);
   begin
      return (Pair_12 and Pair_34 and Pair_56)
        or (Triple_123 and Triple_456);
   end Can_Break;
end Word_Break_Stub;
