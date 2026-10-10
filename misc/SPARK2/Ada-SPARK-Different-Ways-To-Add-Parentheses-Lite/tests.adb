pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Different_Ways_Parentheses; use Different_Ways_Parentheses;
with Own_Checks;

procedure Tests is
   function Img (A : Value_List) return String is
     (if A'Length = 0 then "" else A (A'First)'Image & Img (A (A'First + 1 .. A'Last)));

   procedure Expect (Values : Operand_List; Ops : Operator_List; Want : Value_List) is
      Got : constant Value_List := All_Results (Values, Ops);
   begin
      if Got'First /= 1 or else Got'Length /= Want'Length or else Got /= Want then
         raise Program_Error with "All_Results: got" & Img (Got) & ", expected" & Img (Want);
      end if;
   end Expect;

   Old : constant array (1 .. 8) of Positive := [1, 1, 2, 5, 14, 42, 132, 429];
begin
   for N in Old'Range loop
      if Number_Of_Ways (N) /= Old (N) then
         raise Program_Error with "Number_Of_Ways" & N'Image;
      end if;
   end loop;
   --  Each count is the sum over the last split: W (9) = 1 * 429 + 1 * 132
   --  + 2 * 42 + 5 * 14 + 14 * 5 + 42 * 2 + 132 * 1 + 429 * 1 = 1_430, and
   --  W (10) = 4_862 in the same way. The limit W (20) = 1_767_263_190 fits
   --  Natural; W (21) = 6_564_120_420 would not.
   if Number_Of_Ways (9) /= 1_430 or else Number_Of_Ways (10) /= 4_862
     or else Number_Of_Ways (20) /= 1_767_263_190
   then
      raise Program_Error with "Number_Of_Ways 9 / 10 / 20";
   end if;

   --  Results are listed by the position of the last operator applied
   --  (left to right), then by the left part's results, then by the right
   --  part's results.
   --  3 - 2 * 4 + 1: last "-": 3 - (2 * (4 + 1)) = -7, 3 - ((2 * 4) + 1) = -6;
   --  last "*": (3 - 2) * (4 + 1) = 5; last "+": (3 - (2 * 4)) + 1 = -4,
   --  ((3 - 2) * 4) + 1 = 5.
   Expect ([3, 2, 4, 1], [Minus, Times, Plus], [-7, -6, 5, -4, 5]);
   --  5 * -3 - 7: 5 * (-3 - 7) = -50, (5 * -3) - 7 = -22.
   Expect ([5, -3, 7], [Times, Minus], [-50, -22]);
   Expect ([-99], [], [-99]);
   Expect ([4, 9], [Minus], [-5]);
   --  Eight factors -99: all 429 orders give (-99) ** 8 = 9_227_446_944_279_201.
   Expect ([1 .. 8 => -99], [1 .. 7 => Times], [1 .. 429 => 9_227_446_944_279_201]);
   --  Nine factors -99 (the limit: 99 ** 9 = 913_517_247_483_640_899 fits
   --  Long_Long_Integer, 99 ** 10 would not): W (9) = 1_430 orders, each
   --  (-99) ** 9.
   Expect ([1 .. 9 => -99], [1 .. 8 => Times], [1 .. 1_430 => -913_517_247_483_640_899]);

   --  H191: the bound 99 ** Max_Expression is carried by the element subtype
   --  Result_Value (the results of All_Results and of the internal Sub slots),
   --  not by a run-time quantifier over every slot entry.
   if Result_Value'First /= -Bound (Max_Expression) or else Result_Value'Last /= Bound (Max_Expression)
     or else Bound (Max_Expression) + 1 in Result_Value or else -Bound (Max_Expression) - 1 in Result_Value
   then
      raise Program_Error with "Result_Value is not -Bound (Max_Expression) .. Bound (Max_Expression)";
   end if;

   Own_Checks;
   Put_Line ("PASS Different_Ways_Parentheses");
end Tests;
