--  Pollard's kangaroo (lambda) — Ada 2023 implementation (educational).

pragma Ada_2022;

with Interfaces;

package body Pollards_Kangaroo_Algorithm
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Helpers
   ------------------------------------------------------------------

   function Mul_Mod (A, B, M : U64) return U64 is
      use Interfaces;
      AA, BB, MM, Prod : Unsigned_128;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      AA   := Unsigned_128 (A rem M);
      BB   := Unsigned_128 (B rem M);
      MM   := Unsigned_128 (M);
      Prod := AA * BB;
      return U64 (Unsigned_64 (Prod rem MM));
   end Mul_Mod;

   function Mod_Exp (Base, Exp, Modulus : U64) return U64 is
      Result : U64 := 1;
      B      : U64;
      E      : U64 := Exp;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      if Modulus = 1 then
         return 0;
      end if;
      B := Base rem Modulus;
      while E > 0 loop
         if (E and 1) = 1 then
            Result := Mul_Mod (Result, B, Modulus);
         end if;
         B := Mul_Mod (B, B, Modulus);
         E := E / 2;
      end loop;
      return Result;
   end Mod_Exp;

   function Floor_Sqrt (N : U64) return U64 is
      X, Y : U64;
   begin
      if N <= 1 then
         return N;
      end if;
      X := N;
      Y := (X + 1) / 2;
      while Y < X loop
         X := Y;
         Y := (X + N / X) / 2;
      end loop;
      return X;
   end Floor_Sqrt;

   function Verify_Discrete_Log
     (G, Y, P, X : U64) return Boolean
   is
   begin
      if P < 2 then
         return False;
      end if;
      return Mod_Exp (G, X, P) = (Y rem P);
   end Verify_Discrete_Log;

   ------------------------------------------------------------------
   --  Jump set / tame path (educational arrays)
   ------------------------------------------------------------------

   Max_Jump_Count : constant := 32;
   Max_Path_Len   : constant := 65_536;

   type Jump_Array is array (Natural range <>) of U64;

   type Path_Entry is record
      Element  : U64 := 0;
      Distance : U64 := 0;
   end record;

   type Path_Array is array (0 .. Max_Path_Len - 1) of Path_Entry;

   function Jump_Index (Z : U64; Jump_Count : Natural) return Natural is
   begin
      return Natural (Z rem U64 (Jump_Count));
   end Jump_Index;

   --  Build S = {1, 2, 4, ..., 2^{k-1}} with k chosen so mean(S) ≈ √W.
   procedure Build_Jump_Set
     (Width      : U64;
      Jumps      : out Jump_Array;
      Jump_Count : out Natural)
   is
      Target_Mean : U64;
      Mean        : U64;
      Best_K      : Natural := 8;
      Best_Diff   : U64;
      Pow         : U64;
      Sum         : U64;
      Diff        : U64;
   begin
      if Width = 0 then
         Target_Mean := 1;
      else
         Target_Mean := Floor_Sqrt (Width);
         if Target_Mean = 0 then
            Target_Mean := 1;
         end if;
      end if;

      Best_Diff := U64'Last;
      for K in 4 .. Max_Jump_Count loop
         Pow := 1;
         Sum := 0;
         for I in 1 .. K loop
            Sum := Sum + Pow;
            if I < K then
               if Pow > U64'Last / 2 then
                  Pow := U64'Last;
               else
                  Pow := Pow * 2;
               end if;
            end if;
         end loop;
         Mean := Sum / U64 (K);
         if Mean >= Target_Mean then
            Diff := Mean - Target_Mean;
         else
            Diff := Target_Mean - Mean;
         end if;
         if Diff < Best_Diff then
            Best_Diff := Diff;
            Best_K    := K;
         end if;
      end loop;

      Jump_Count := Best_K;
      Pow        := 1;
      for I in 0 .. Jump_Count - 1 loop
         Jumps (I) := Pow;
         if I < Jump_Count - 1 then
            if Pow > U64'Last / 2 then
               Pow := U64'Last;
            else
               Pow := Pow * 2;
            end if;
         end if;
      end loop;
   end Build_Jump_Set;

   --  Try every tame landing that matches Wild_Pos; return first verified X.
   function Recover_From_Path
     (Path      : Path_Array;
      Path_Len  : Natural;
      Wild_Pos  : U64;
      Wild_Dist : U64;
      G_Mod, Y_Mod, P, A, B : U64;
      X_Out     : out U64) return Boolean
   is
      Candidate : U64;
   begin
      for I in 0 .. Path_Len - 1 loop
         if Path (I).Element = Wild_Pos then
            if B + Path (I).Distance >= Wild_Dist then
               Candidate := B + Path (I).Distance - Wild_Dist;
               if Candidate >= A and then Candidate <= B
                 and then Verify_Discrete_Log (G_Mod, Y_Mod, P, Candidate)
               then
                  X_Out := Candidate;
                  return True;
               end if;
            end if;
         end if;
      end loop;
      return False;
   end Recover_From_Path;

   ------------------------------------------------------------------
   --  Core solve
   ------------------------------------------------------------------

   function Try_Solve_Kangaroo
     (P         : U64;
      G         : U64;
      Y         : U64;
      A         : U64;
      B         : U64;
      Max_Steps : Natural := Default_Max_Steps) return Kangaroo_Result
   is
      Result       : Kangaroo_Result;
      Width        : U64;
      Jumps        : Jump_Array (0 .. Max_Jump_Count - 1);
      Jump_Muls    : Jump_Array (0 .. Max_Jump_Count - 1);
      Jump_Count   : Natural;
      Path         : Path_Array;
      Path_Len     : Natural := 0;
      Tame_Pos     : U64;
      Tame_Dist    : U64;
      Wild_Pos     : U64;
      Wild_Dist    : U64;
      Sqrt_W       : U64;
      Tame_Budget  : Natural;
      Wild_Budget  : Natural;
      JI           : Natural;
      Jump         : U64;
      Candidate    : U64;
      G_Mod        : U64;
      Y_Mod        : U64;
      Ideal        : U64;
      Limit_Dist   : U64;
   begin
      if P < 2 then
         raise Invalid_Argument;
      end if;
      if Max_Steps = 0 then
         raise Invalid_Argument;
      end if;
      if A > B then
         raise Invalid_Argument;
      end if;
      Width := B - A;
      if Width > Max_Educational_Width then
         raise Invalid_Argument;
      end if;

      G_Mod := G rem P;
      Y_Mod := Y rem P;
      if G_Mod = 0 or else Y_Mod = 0 then
         raise Invalid_Argument;
      end if;

      if Width = 0 then
         if Mod_Exp (G_Mod, A, P) = Y_Mod then
            Result.Found := True;
            Result.X     := A;
            return Result;
         else
            return Result;
         end if;
      end if;

      --  Tiny intervals: brute force is exact and avoids small-group
      --  spurious collisions drowning a short kangaroo trail.
      if Width <= 4_096 then
         declare
            X : U64 := A;
         begin
            loop
               if Mod_Exp (G_Mod, X, P) = Y_Mod then
                  Result.Found := True;
                  Result.X     := X;
                  return Result;
               end if;
               exit when X = B;
               X := X + 1;
            end loop;
            return Result;
         end;
      end if;

      Build_Jump_Set (Width, Jumps, Jump_Count);
      for I in 0 .. Jump_Count - 1 loop
         Jump_Muls (I) := Mod_Exp (G_Mod, Jumps (I), P);
      end loop;

      Sqrt_W := Floor_Sqrt (Width);
      if Sqrt_W < 1 then
         Sqrt_W := 1;
      end if;

      --  Longer tame trail improves catch probability (~ c·√W steps).
      Ideal := Sqrt_W * 8;
      if Ideal < 64 then
         Ideal := 64;
      end if;
      if Ideal > U64 (Max_Steps / 2) then
         Ideal := U64 (Max_Steps / 2);
      end if;
      if Ideal > U64 (Max_Path_Len - 1) then
         Ideal := U64 (Max_Path_Len - 1);
      end if;
      Tame_Budget := Natural (Ideal);
      Wild_Budget := Max_Steps - Tame_Budget;

      --  Tame kangaroo starts at G^B (Wikipedia-faithful).
      Tame_Pos  := Mod_Exp (G_Mod, B, P);
      Tame_Dist := 0;
      Path (0)  := (Element => Tame_Pos, Distance => Tame_Dist);
      Path_Len  := 1;

      for Step in 1 .. Tame_Budget loop
         JI        := Jump_Index (Tame_Pos, Jump_Count);
         Jump      := Jumps (JI);
         Tame_Pos  := Mul_Mod (Tame_Pos, Jump_Muls (JI), P);
         Tame_Dist := Tame_Dist + Jump;
         if Path_Len >= Max_Path_Len then
            exit;
         end if;
         Path (Path_Len) := (Element => Tame_Pos, Distance => Tame_Dist);
         Path_Len := Path_Len + 1;
      end loop;

      --  Wild may travel a little past the classical B−A+d trap bound.
      Limit_Dist := Width + Tame_Dist + Width;

      --  Wild kangaroo starts at Y.
      Wild_Pos  := Y_Mod;
      Wild_Dist := 0;

      if Recover_From_Path
        (Path, Path_Len, Wild_Pos, Wild_Dist, G_Mod, Y_Mod, P, A, B, Candidate)
      then
         Result.Found := True;
         Result.X     := Candidate;
         return Result;
      end if;

      for Step in 1 .. Wild_Budget loop
         JI        := Jump_Index (Wild_Pos, Jump_Count);
         Jump      := Jumps (JI);
         Wild_Pos  := Mul_Mod (Wild_Pos, Jump_Muls (JI), P);
         Wild_Dist := Wild_Dist + Jump;

         if Recover_From_Path
           (Path, Path_Len, Wild_Pos, Wild_Dist,
            G_Mod, Y_Mod, P, A, B, Candidate)
         then
            Result.Found := True;
            Result.X     := Candidate;
            return Result;
         end if;

         if Wild_Dist > Limit_Dist then
            exit;
         end if;
      end loop;

      return Result;
   end Try_Solve_Kangaroo;

   function Solve_Kangaroo
     (P         : U64;
      G         : U64;
      Y         : U64;
      A         : U64;
      B         : U64;
      Max_Steps : Natural := Default_Max_Steps) return U64
   is
      R : constant Kangaroo_Result :=
        Try_Solve_Kangaroo (P, G, Y, A, B, Max_Steps);
   begin
      if not R.Found then
         raise Not_Found;
      end if;
      return R.X;
   end Solve_Kangaroo;

end Pollards_Kangaroo_Algorithm;
