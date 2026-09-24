-- Sieve of Sundaram - Package Body
package body Sieve_Of_Sundaram is

   -----------------------------------------------------------------------------
   -- VARIANT 1: Standard Sundaram
   -----------------------------------------------------------------------------
   function Standard_Sundaram (Limit : Integer) return Prime_Array is
   begin
      -- Edge cases for limits below the first prime (2)
      if Limit < 2 then
         return (1 .. 0 => 0); -- Return empty array
      elsif Limit = 2 then
         return (1 => 2);      -- 2 is prime, but Sundaram only generates odd primes
      end if;

      declare
         -- The maximum index K such that 2K + 1 <= Limit
         K : constant Integer := (Limit - 1) / 2;
         Marked : array (1 .. K) of Boolean := (others => False);
         Count  : Natural := 1; -- We start at 1 because '2' is prime and explicitly added
         Index  : Positive := 2;
      begin
         -- Core Sieve of Sundaram Logic
         -- Remove all numbers of the form i + j + 2ij
         for I in 1 .. K loop
            for J in I .. (K - I) / (2 * I + 1) loop
               Marked (I + J + 2 * I * J) := True;
            end loop;
         end loop;

         -- First pass: Count unmarked cells to allocate exact array size
         for I in 1 .. K loop
            if not Marked (I) then
               Count := Count + 1;
            end if;
         end loop;

         declare
            -- Dynamic allocation strictly based on computed result
            Result : Prime_Array (1 .. Count);
         begin
            Result(1) := 2; -- Explicitly insert the only even prime
            
            -- Second pass: populate primes as 2m + 1
            for I in 1 .. K loop
               if not Marked (I) then
                  Result (Index) := 2 * I + 1;
                  Index := Index + 1;
               end if;
            end loop;
            
            return Result;
         end;
      end;
   end Standard_Sundaram;

   -----------------------------------------------------------------------------
   -- VARIANT 2: Count-Only (No Array Population)
   -----------------------------------------------------------------------------
   function Count_Primes_Sundaram (Limit : Integer) return Natural is
   begin
      if Limit < 2 then
         return 0;
      end if;

      declare
         K : constant Integer := (Limit - 1) / 2;
         Marked : array (1 .. K) of Boolean := (others => False);
         Count  : Natural := 1;
      begin
         for I in 1 .. K loop
            for J in I .. (K - I) / (2 * I + 1) loop
               Marked (I + J + 2 * I * J) := True;
            end loop;
         end loop;

         for I in 1 .. K loop
            if not Marked (I) then
               Count := Count + 1;
            end if;
         end loop;

         return Count;
      end;
   end Count_Primes_Sundaram;

   -----------------------------------------------------------------------------
   -- VARIANT 3: Single Primality Test via Sundaram Core Function
   -----------------------------------------------------------------------------
   function Is_Prime_Sundaram (N : Integer) return Boolean is
   begin
      if N < 2 then
         return False;
      elsif N = 2 then
         return True;
      elsif N mod 2 = 0 then
         return False; -- Evens > 2 are not prime
      else
         declare
            -- For an odd number N > 2, N = 2K + 1, so K = (N - 1) / 2.
            -- We verify if K can be expressed as I + J + 2*I*J.
            K : constant Integer := (N - 1) / 2;
         begin
            for I in 1 .. K loop
               for J in I .. (K - I) / (2 * I + 1) loop
                  if I + J + 2 * I * J = K then
                     -- A match means the number is composite
                     return False;
                  end if;
               end loop;
            end loop;
            -- If no combinations factor K out, N is prime
            return True;
         end;
      end if;
   end Is_Prime_Sundaram;

end Sieve_Of_Sundaram;
