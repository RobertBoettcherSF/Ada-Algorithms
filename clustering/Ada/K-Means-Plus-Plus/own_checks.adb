--  D^2 fairness for k-means++. The draws are a fixed grid, not a fresh
--  seed. Points on a line: 0, 1 and 3. The first draw is 0, so the first
--  center is 0. Squared distances to it are 0, 1 and 9, so the second
--  center is the point at 1 with probability 1/10 and the point at 3
--  with probability 9/10.
--  U set: (I + 0.5) / 1000 for I in 0 .. 999. Expected counts 100 and 900.
--  df = 1. 6.635 is the chi-square point for p = 0.01.

pragma Ada_2022;

with Ada.Text_IO;
with K_Means_Plus_Plus;

procedure Own_Checks (Fail_Count : out Natural) is
   use K_Means_Plus_Plus;
   package Txt renames Ada.Text_IO;

   Checks : Natural := 0;
   Fails  : Natural := 0;

   procedure Note (OK : Boolean; Label : String) is
   begin
      Checks := Checks + 1;
      if not OK then
         Fails := Fails + 1;
         Txt.Put_Line ("  FAIL -- " & Label);
      end if;
   end Note;

   Data : constant Dataset :=
     [[0.0],
      [1.0],
      [3.0]];
   At_1 : Natural := 0;
   At_3 : Natural := 0;
   Other : Natural := 0;
begin
   Fail_Count := 0;
   Txt.Put_Line ("own checks U grid: (I + 1/2) / 1000, I = 0 .. 999;"
     & " first draw 0; threshold 6.635 (df 1, p = 0.01)");

   for I in 0 .. 999 loop
      declare
         U : constant Unit_Interval := Unit_Interval ((Real (I) + 0.5) / 1000.0);
         Got : constant Centers :=
           Init_Centers_KMeansPP (Data, 2, [0.0, U]);
      begin
         if abs (Got (1, 1) - 0.0) > 1.0e-9 then
            Other := Other + 1;
         elsif abs (Got (2, 1) - 1.0) <= 1.0e-9 then
            At_1 := At_1 + 1;
         elsif abs (Got (2, 1) - 3.0) <= 1.0e-9 then
            At_3 := At_3 + 1;
         else
            Other := Other + 1;
         end if;
      end;
   end loop;

   declare
      D1 : constant Real := Real (At_1) - 100.0;
      D3 : constant Real := Real (At_3) - 900.0;
      Stat : constant Real := D1 * D1 / 100.0 + D3 * D3 / 900.0;
   begin
      Note (Other = 0, "every second center is the point at 1 or at 3");
      Note (Stat < 6.635, "D^2 picks match 1/10 and 9/10");
   end;

   declare
      Near : constant Centers :=
        Init_Centers_KMeansPP (Data, 2, [0.0, 0.05]);
      Far : constant Centers :=
        Init_Centers_KMeansPP (Data, 2, [0.0, 0.5]);
   begin
      Note (abs (Near (2, 1) - 1.0) <= 1.0e-9,
        "U = 0.05, inside the weight-1 bin, picks the point at 1");
      Note (abs (Far (2, 1) - 3.0) <= 1.0e-9,
        "U = 0.5, inside the weight-9 bin, picks the point at 3");
   end;

   Txt.Put_Line ("own checks:" & Natural'Image (Checks)
     & "  failed:" & Natural'Image (Fails));
   Fail_Count := Fails;
end Own_Checks;
