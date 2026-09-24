pragma Ada_2022;
package body Decode_Ways_Stub with SPARK_Mode => On is
   function Count (D : Digit_Seq) return Ways is
      W0 : constant Natural := 1;
      W1 : constant Natural := (if D (1) = 0 then 0 else 1);
      W2 : constant Natural :=
        (if D (2) = 0 then
            (if D (1) = 1 or D (1) = 2 then W0 else 0)
         elsif D (1) = 1 or D (1) = 2 then W0 + W1
         else W1);
      W3 : constant Natural :=
        (if D (3) = 0 then
            (if D (2) = 1 or D (2) = 2 then W1 else 0)
         elsif D (2) = 1 or D (2) = 2 then W1 + W2
         else W2);
      W4 : constant Natural :=
        (if D (4) = 0 then
            (if D (3) = 1 or D (3) = 2 then W2 else 0)
         elsif D (3) = 1 or D (3) = 2 then W2 + W3
         else W3);
      W5 : constant Natural :=
        (if D (5) = 0 then
            (if D (4) = 1 or D (4) = 2 then W3 else 0)
         elsif D (4) = 1 or D (4) = 2 then W3 + W4
         else W4);
      W6 : constant Natural :=
        (if D (6) = 0 then
            (if D (5) = 1 or D (5) = 2 then W4 else 0)
         elsif D (5) = 1 or D (5) = 2 then W4 + W5
         else W5);
   begin
      return Ways (W6);
   end Count;
end Decode_Ways_Stub;
