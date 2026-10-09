pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Super_Ugly_Number_Stub; use Super_Ugly_Number_Stub;
--  Own checks (H114): the N-th super ugly number for a given factor list
--  (the N-th smallest positive integer that is a product of the factors,
--  1 = empty product). Reference 1 (values <= 200,000): test every integer
--  by dividing out the factors. Reference 2 (large N): all products up to a
--  limit by depth-first search, then sorted. Seed 20261009, Park-Miller.
procedure Own_Checks is
   Fails : Natural := 0;
   Cases : Natural := 0;
   Seed  : Long_Long_Integer := 20261009;

   function Rand (N : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2_147_483_647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Rand;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      Cases := Cases + 1;
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 5 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   function Product_Of (X : Positive; F : Factor_List) return Boolean is
      Y : Natural := X;
      Changed : Boolean := True;
   begin
      while Y > 1 and then Changed loop
         Changed := False;
         for J in F'Range loop
            if Y mod F (J) = 0 then
               Y := Y / F (J);
               Changed := True;
            end if;
         end loop;
      end loop;
      return Y = 1;
   end Product_Of;

   --  Reference 1: N-th product of F by trial (0 when above Limit).
   function Ref_Trial (F : Factor_List; N : Positive; Limit : Positive) return Natural is
      C : Natural := 0;
   begin
      for X in 1 .. Limit loop
         if Product_Of (X, F) then
            C := C + 1;
            if C = N then
               return X;
            end if;
         end if;
      end loop;
      return 0;
   end Ref_Trial;

   procedure Compare (F : Factor_List; N : N_Range; Want : Long_Long_Integer; Tag : String) is
      V : Ugly_Value;
      Ok : Boolean;
   begin
      Nth_Super_Ugly_General (F, N, V, Ok);
      if Want > Long_Long_Integer (Ugly_Value'Last) then
         Check (not Ok, "expected not Fits" & Tag);
      else
         Check (Ok and then Long_Long_Integer (V) = Want, "value" & Tag & " got" & V'Image & " want" & Want'Image);
      end if;
   exception
      when Constraint_Error =>
         Check (False, "rejected" & Tag);
   end Compare;

   --  Reference 2: every product <= Limit (DFS over factor exponents), sorted.
   type LL_Array is array (Positive range <>) of Long_Long_Integer;
   procedure Products (F : Factor_List; Limit : Long_Long_Integer; Out_A : out LL_Array; Count : out Natural) is
      procedure Dfs (J : Positive; P : Long_Long_Integer) is
         Q : Long_Long_Integer := P;
      begin
         if J > F'Last then
            Count := Count + 1;
            Out_A (Count) := P;
            return;
         end if;
         loop
            Dfs (J + 1, Q);
            exit when Q > Limit / Long_Long_Integer (F (J));
            Q := Q * Long_Long_Integer (F (J));
         end loop;
      end Dfs;
   begin
      Count := 0;
      Out_A := [others => 0];
      Dfs (F'First, 1);
      --  insertion sort is too slow for 10**5; shell sort
      declare
         Gap : Natural := Count / 2;
         T   : Long_Long_Integer;
         K   : Natural;
      begin
         while Gap > 0 loop
            for I in Gap + 1 .. Count loop
               T := Out_A (I);
               K := I;
               while K > Gap and then Out_A (K - Gap) > T loop
                  Out_A (K) := Out_A (K - Gap);
                  K := K - Gap;
               end loop;
               Out_A (K) := T;
            end loop;
            Gap := Gap / 2;
         end loop;
      end;
   end Products;

   Primes : constant array (1 .. 25) of Factor_Value :=
     [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97];
begin
   --  the original fixed set (2, 7, 13, 19) for N = 1 .. 12
   for N in N_Index loop
      Check (Nth_Super_Ugly (N) = Ref_Trial ([2, 7, 13, 19], N, 10_000), "fixed set N =" & N'Image);
   end loop;
   --  random factor lists (also non-primes and repeats), small values
   for T in 1 .. 300 loop
      declare
         M : constant Positive := 1 + Rand (4);
         F : Factor_List (1 .. M);
      begin
         for J in 1 .. M loop
            F (J) := (if Rand (3) = 0 then 2 + Rand (30) else Primes (1 + Rand (10)));
         end loop;
         for N in 1 .. 40 loop
            declare
               W : constant Natural := Ref_Trial (F, N, 200_000);
            begin
               exit when W = 0;
               Compare (F, N, Long_Long_Integer (W), " trial T =" & T'Image & " N =" & N'Image);
            end;
         end loop;
      end;
   end loop;
   --  large N against the sorted product list (and the 32-bit boundary)
   declare
      Sets : constant array (1 .. 3) of Natural := [1, 4, 10];
      A : LL_Array (1 .. 400_000);
      C : Natural;
   begin
      for S of Sets loop
         declare
            F : Factor_List (1 .. S);
         begin
            for J in 1 .. S loop
               F (J) := Primes (J);
            end loop;
            Products (F, 4 * Long_Long_Integer (Integer'Last), A, C);
            for T in 1 .. 200 loop
               declare
                  N : constant Positive := 1 + Rand (Natural'Min (C, N_Range'Last));
               begin
                  Compare (F, N, A (N), " sorted set" & S'Image & " N =" & N'Image);
               end;
            end loop;
            if C < N_Range'Last then
               --  the first value above Integer'Last: Fits must be False
               for N in 1 .. C loop
                  if A (N) > Long_Long_Integer (Integer'Last) then
                     Compare (F, N, A (N), " first above 2**31 - 1, set" & S'Image);
                     exit;
                  end if;
               end loop;
            end if;
         end;
      end loop;
   end;
   if Fails = 0 then
      Put_Line ("PASS Super_Ugly_Number own checks:" & Cases'Image & " checks (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Cases'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
