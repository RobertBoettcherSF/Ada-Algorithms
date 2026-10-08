-- ============================================================================
-- Package Body: Hidden_Shift
-- Description: Implementation of hidden shift solvers and verification utilities.
-- ============================================================================

package body Hidden_Shift is

   ---------------------------------------------------------------------------
   -- Verify_Shift
   ---------------------------------------------------------------------------
   function Verify_Shift (F : Function_Table; G : Function_Table; Shift : Domain_Element) return Boolean is
   begin
      for X in Domain_Element loop
         if G (X) /= F (X + Shift) then
            return False;
         end if;
      end loop;
      return True;
   end Verify_Shift;

   ---------------------------------------------------------------------------
   -- Compute_Correlation
   ---------------------------------------------------------------------------
   function Compute_Correlation (F : Function_Table; G : Function_Table; Shift : Domain_Element) return Natural is
      Score : Natural := 0;
   begin
      for X in Domain_Element loop
         if G (X) = F (X + Shift) then
            Score := Score + 1;
         end if;
      end loop;
      return Score;
   end Compute_Correlation;

   ---------------------------------------------------------------------------
   -- Solve_Brute_Force
   ---------------------------------------------------------------------------
   function Solve_Brute_Force (F : Function_Table; G : Function_Table) return Domain_Element is
   begin
      -- Exhaustive search over all elements of the cyclic domain Z_16
      for S in Domain_Element loop
         if Verify_Shift (F, G, S) then
            return S;
         end if;
      end loop;
      
      raise No_Shift_Found with "No valid hidden shift exists for the given functions F and G.";
   end Solve_Brute_Force;

   ---------------------------------------------------------------------------
   -- Solve_Correlation_Search
   ---------------------------------------------------------------------------
   function Solve_Correlation_Search (F : Function_Table; G : Function_Table) return Domain_Element is
      Best_Shift : Domain_Element := 0;
      Max_Score  : Natural := 0;
      Score      : Natural;
   begin
      -- Find the shift that maximizes agreement between G(x) and F(x + s)
      for S in Domain_Element loop
         Score := Compute_Correlation (F, G, S);
         if Score > Max_Score then
            Max_Score := Score;
            Best_Shift := S;
         end if;
      end loop;

      if Max_Score = 0 then
         raise No_Shift_Found with "Correlation search found no matching overlap between F and G.";
      end if;

      return Best_Shift;
   end Solve_Correlation_Search;

end Hidden_Shift;
