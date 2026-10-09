--  tests_reference.adb
--  Every dithering procedure against a deliberately simple reference:
--  error diffusion as one generic kernel walk (offset / weight table),
--  threshold and 2x2 Bayer as direct formulas. 2,000 seeded random images
--  (seed 20261009, sizes 1 .. 7 x 1 .. 7, lower bounds 0 or 3, values in
--  -0.25 .. 1.25) must match exactly. Also: on flat grey images the share
--  of white pixels must match the grey level (mean preservation).

with Ada.Text_IO;      use Ada.Text_IO;
with Ada.Command_Line;
with Dithering;        use Dithering;

procedure Tests_Reference is
   Fails : Natural := 0;

   procedure Check (Cond : Boolean; Name : String);
   procedure Check (Cond : Boolean; Name : String) is
   begin
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 20 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   State : Long_Long_Integer := 20261009;
   function Next (M : Positive) return Natural;
   function Next (M : Positive) return Natural is
   begin
      State := (State * 1103515245 + 12345) mod 2**31;
      return Natural (State / 65536 mod Long_Long_Integer (M));
   end Next;

   type Tap is record
      DY, DX : Integer;
      W      : Color_Value;
   end record;
   type Kernel is array (Positive range <>) of Tap;

   FS : constant Kernel :=
     ((0, 1, 7.0), (1, -1, 3.0), (1, 0, 5.0), (1, 1, 1.0));
   Atk : constant Kernel :=
     ((0, 1, 1.0), (0, 2, 1.0), (1, -1, 1.0), (1, 0, 1.0), (1, 1, 1.0),
      (2, 0, 1.0));
   JJN : constant Kernel :=
     ((0, 1, 7.0), (0, 2, 5.0),
      (1, -2, 3.0), (1, -1, 5.0), (1, 0, 7.0), (1, 1, 5.0), (1, 2, 3.0),
      (2, -2, 1.0), (2, -1, 3.0), (2, 0, 5.0), (2, 1, 3.0), (2, 2, 1.0));
   Stu : constant Kernel :=
     ((0, 1, 8.0), (0, 2, 4.0),
      (1, -2, 2.0), (1, -1, 4.0), (1, 0, 8.0), (1, 1, 4.0), (1, 2, 2.0),
      (2, -2, 1.0), (2, -1, 2.0), (2, 0, 4.0), (2, 1, 2.0), (2, 2, 1.0));

   --  Generic error diffusion in scan order. Floyd-Steinberg scales the
   --  error as E * (W / 16); the others as (E / Divisor) * W, the same
   --  operation order as the library, so results must match exactly.
   procedure Diffuse
     (Img : in out Image; K : Kernel; Div : Color_Value; Per_Tap : Boolean);
   procedure Diffuse
     (Img : in out Image; K : Kernel; Div : Color_Value; Per_Tap : Boolean)
   is
      Old, Q, E : Color_Value;
   begin
      for Y in Img'Range (1) loop
         for X in Img'Range (2) loop
            Old := Img (Y, X);
            Q := (if Old < 0.0 then 0.0 elsif Old < 0.5 then 0.0 else 1.0);
            Img (Y, X) := Q;
            for T of K loop
               if Y + T.DY in Img'Range (1) and then X + T.DX in Img'Range (2)
               then
                  if Per_Tap then
                     E := (Old - Q) * (T.W / Div);
                  else
                     E := (Old - Q) / Div * T.W;
                  end if;
                  Img (Y + T.DY, X + T.DX) := Img (Y + T.DY, X + T.DX) + E;
               end if;
            end loop;
         end loop;
      end loop;
   end Diffuse;

   function Bayer (Y, X : Natural) return Color_Value is
     (case 2 * (Y mod 2) + (X mod 2) is
         when 0 => 0.0, when 1 => 0.5, when 2 => 0.75, when others => 0.25);

   procedure Random_Image (Img : out Image);
   procedure Random_Image (Img : out Image) is
   begin
      for Y in Img'Range (1) loop
         for X in Img'Range (2) loop
            Img (Y, X) := Color_Value (Next (97)) / 64.0 - 0.25;
         end loop;
      end loop;
   end Random_Image;

   --  Share of white pixels after dithering a flat grey image
   type Proc is access procedure (Img : in out Image);
   function White_Share (P : Proc; Grey : Color_Value) return Float;
   function White_Share (P : Proc; Grey : Color_Value) return Float is
      Img   : Image (0 .. 63, 0 .. 63) := (others => (others => Grey));
      Count : Natural := 0;
   begin
      P (Img);
      for V of Img loop
         if V = 1.0 then
            Count := Count + 1;
         end if;
      end loop;
      return Float (Count) / 4096.0;
   end White_Share;

   type Color_Value_Array is array (Positive range <>) of Color_Value;
   Diffs : array (1 .. 6) of Natural := (others => 0);
begin
   for N in 1 .. 2_000 loop
      declare
         H  : constant Positive := 1 + Next (7);
         W  : constant Positive := 1 + Next (7);
         FY : constant Natural := 3 * Next (2);
         FX : constant Natural := 3 * Next (2);
         Src, A, B : Image (FY .. FY + H - 1, FX .. FX + W - 1);
      begin
         Random_Image (Src);

         A := Src; B := Src;
         Floyd_Steinberg_Dither (A); Diffuse (B, FS, 16.0, True);
         Diffs (1) := Diffs (1) + (if A = B then 0 else 1);

         A := Src; B := Src;
         Atkinson_Dither (A); Diffuse (B, Atk, 8.0, False);
         Diffs (2) := Diffs (2) + (if A = B then 0 else 1);

         A := Src; B := Src;
         Jarvis_Judice_Ninke_Dither (A); Diffuse (B, JJN, 48.0, False);
         Diffs (3) := Diffs (3) + (if A = B then 0 else 1);

         A := Src; B := Src;
         Stucki_Dither (A); Diffuse (B, Stu, 42.0, False);
         Diffs (4) := Diffs (4) + (if A = B then 0 else 1);

         A := Src;
         Threshold_Dither (A, 0.5);
         for Y in A'Range (1) loop
            for X in A'Range (2) loop
               if A (Y, X) /= (if Src (Y, X) >= 0.5 then 1.0 else 0.0) then
                  Diffs (5) := Diffs (5) + 1;
               end if;
            end loop;
         end loop;

         A := Src;
         Ordered_Dither_2x2 (A);
         for Y in A'Range (1) loop
            for X in A'Range (2) loop
               if A (Y, X) /=
                 (if Color_Value'Min (1.0, Color_Value'Max (0.0, Src (Y, X)))
                    >= 1.0 - Bayer (Y - FY, X - FX)
                  then 1.0 else 0.0)
               then
                  Diffs (6) := Diffs (6) + 1;
               end if;
            end loop;
         end loop;
      end;
   end loop;
   Check (Diffs (1) = 0, "Floyd-Steinberg vs reference:" & Diffs (1)'Img);
   Check (Diffs (2) = 0, "Atkinson vs reference:" & Diffs (2)'Img);
   Check (Diffs (3) = 0, "Jarvis-Judice-Ninke vs reference:" & Diffs (3)'Img);
   Check (Diffs (4) = 0, "Stucki vs reference:" & Diffs (4)'Img);
   Check (Diffs (5) = 0, "Threshold vs reference:" & Diffs (5)'Img);
   Check (Diffs (6) = 0, "Ordered 2x2 vs reference:" & Diffs (6)'Img);

   --  Mean preservation on flat greys (Atkinson diffuses only 6/8 of the
   --  error, so it is checked only at 1/4, 1/2, 3/4 to a looser bound)
   for G of Color_Value_Array'(0.1, 0.25, 0.5, 0.7, 0.9) loop
      Check (abs (White_Share (Floyd_Steinberg_Dither'Access, G) - Float (G))
             < 0.02, "Floyd-Steinberg mean at" & G'Img);
      Check (abs (White_Share (Jarvis_Judice_Ninke_Dither'Access, G)
                  - Float (G)) < 0.02, "JJN mean at" & G'Img);
      Check (abs (White_Share (Stucki_Dither'Access, G) - Float (G))
             < 0.02, "Stucki mean at" & G'Img);
      Check (abs (White_Share (Ordered_Dither_2x2'Access, G) - Float (G))
             < 0.26, "Ordered 2x2 mean at" & G'Img);
   end loop;
   for G of Color_Value_Array'(0.25, 0.5, 0.75) loop
      Check (abs (White_Share (Atkinson_Dither'Access, G) - Float (G))
             < 0.1, "Atkinson mean at" & G'Img);
   end loop;

   if Fails = 0 then
      Put_Line ("PASS Dithering reference comparison (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Img & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests_Reference;
