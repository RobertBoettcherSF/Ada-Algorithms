with Ada.Containers.Hashed_Maps;
with Ada.Containers.Hashed_Sets;
with Ada.Numerics.Discrete_Random;
with Ada.Numerics.Elementary_Functions;

package body BHT_Algorithm is

   use type Ada.Containers.Count_Type;

   -- Hash functions for internal sets and maps
   function Hash_Range (Key : Range_Value) return Ada.Containers.Hash_Type is
   begin
      return Ada.Containers.Hash_Type (Key);
   end Hash_Range;

   function Hash_Domain (Key : Domain_Value) return Ada.Containers.Hash_Type is
   begin
      return Ada.Containers.Hash_Type (Key);
   end Hash_Domain;

   -- Data structures for classical querying phase
   package Value_Map is new Ada.Containers.Hashed_Maps
     (Key_Type        => Range_Value,
      Element_Type    => Domain_Value,
      Hash            => Hash_Range,
      Equivalent_Keys => "=");

   package Domain_Set is new Ada.Containers.Hashed_Sets
     (Element_Type        => Domain_Value,
      Hash                => Hash_Domain,
      Equivalent_Elements => "=");

   -- Compute required classical queries K = (N / R) ^ (1/3)
   function Compute_K (N : Domain_Value; R : Positive) return Domain_Value is
      use Ada.Numerics.Elementary_Functions;
      Float_N : constant Float := Float (N);
      Float_R : constant Float := Float (R);
      K_Float : constant Float := (Float_N / Float_R) ** (1.0 / 3.0);
      K_Int   : constant Integer := Integer (K_Float);
   begin
      if K_Int < 1 then
         return 1;
      elsif K_Int > Integer (N) then
         return N;
      else
         return Domain_Value (K_Int);
      end if;
   end Compute_K;

   -- Core BHT simulation logic uniting classical mapping and simulated quantum fallback
   procedure Core_Algorithm
     (Domain_Size : Domain_Value;
      K           : Domain_Value;
      Oracle      : Oracle_Function;
      Result      : out Collision_Pair;
      Found       : out Boolean)
   is
      package Random_Domain is new Ada.Numerics.Discrete_Random (Domain_Value);
      Gen : Random_Domain.Generator;
      
      Map        : Value_Map.Map;
      Queried_Xs : Domain_Set.Set;
      X          : Domain_Value;
      Y          : Range_Value;
   begin
      Found := False;
      Result := (X1 => 1, X2 => 1); -- Default initialization

      Random_Domain.Reset (Gen);

      -- Phase 1: Classical preparation (Birthday Paradox mechanics)
      -- Select K unique random elements, evaluate them, store mapping.
      while Value_Map.Length (Map) < Ada.Containers.Count_Type (K) loop
         -- Generate a bounded element safely across exact limits
         X := (Random_Domain.Random (Gen) mod Domain_Size) + 1;
         
         if not Queried_Xs.Contains (X) then
            Queried_Xs.Insert (X);
            Y := Oracle (X);
            
            if Value_Map.Contains (Map, Y) then
               -- Collision found purely in the classical preparation step
               Result := (X1 => Value_Map.Element (Map, Y), X2 => X);
               Found := True;
               return;
            else
               Value_Map.Insert (Map, Y, X);
            end if;
         end if;
         
         -- Escape hatch if we exhaust domain before reaching K (dense domains)
         if Queried_Xs.Length >= Ada.Containers.Count_Type (Domain_Size) then
            exit;
         end if;
      end loop;

      -- Phase 2: Simulated Quantum Search (Grover's Algorithm representation)
      -- Normally, Grover finds an unmapped x in O(sqrt(N/K)) time. We simulate
      -- this behavior logically by conventionally searching remaining elements.
      for Cand_X in Domain_Value range 1 .. Domain_Size loop
         if not Queried_Xs.Contains (Cand_X) then
            Y := Oracle (Cand_X);
            if Value_Map.Contains (Map, Y) then
               Result := (X1 => Value_Map.Element (Map, Y), X2 => Cand_X);
               Found := True;
               return;
            end if;
         end if;
      end loop;
   end Core_Algorithm;

   procedure Simulate_BHT_2_To_1
     (Domain_Size : Domain_Value;
      Oracle      : Oracle_Function;
      Result      : out Collision_Pair;
      Found       : out Boolean)
   is
      K : Domain_Value;
   begin
      if Domain_Size < 2 then
         raise Invalid_Domain_Error with "Domain_Size must be >= 2 for 2-to-1 BHT";
      end if;
      if Oracle = null then
         raise Null_Oracle_Error with "Oracle function cannot be null";
      end if;
      
      K := Compute_K (Domain_Size, 2);
      Core_Algorithm (Domain_Size, K, Oracle, Result, Found);
   end Simulate_BHT_2_To_1;

   procedure Simulate_BHT_R_To_1
     (Domain_Size : Domain_Value;
      R           : Positive;
      Oracle      : Oracle_Function;
      Result      : out Collision_Pair;
      Found       : out Boolean)
   is
      K : Domain_Value;
   begin
      if R < 2 then
         raise Invalid_R_Error with "R must be >= 2";
      end if;
      if Domain_Size < Domain_Value (R) then
         raise Invalid_Domain_Error with "Domain_Size must be >= R";
      end if;
      if Oracle = null then
         raise Null_Oracle_Error with "Oracle function cannot be null";
      end if;
      
      K := Compute_K (Domain_Size, R);
      Core_Algorithm (Domain_Size, K, Oracle, Result, Found);
   end Simulate_BHT_R_To_1;

end BHT_Algorithm;
