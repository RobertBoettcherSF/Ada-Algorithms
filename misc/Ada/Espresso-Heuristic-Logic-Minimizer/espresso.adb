package body Espresso is

   function Overlaps (A, B : Cube) return Boolean is
   begin
      for I in A'Range loop
         --  If one cube requires Zero and the other requires One, they don't overlap.
         if A (I) /= Dont_Care and then B (I) /= Dont_Care and then A (I) /= B (I) then
            return False;
         end if;
      end loop;
      return True;
   end Overlaps;

   function Subsumes (A, B : Cube) return Boolean is
   begin
      for I in A'Range loop
         --  A subsumes B only if A is broad (Dont_Care) or matches B exactly at I.
         if A (I) /= Dont_Care and then A (I) /= B (I) then
            return False;
         end if;
      end loop;
      return True;
   end Subsumes;

   function Is_Uniform (C : Cover) return Boolean is
   begin
      if C.Is_Empty then
         return True;
      end if;

      declare
         Expected_Length : constant Natural := C.First_Element'Length;
      begin
         for X of C loop
            if X'Length /= Expected_Length then
               return False;
            end if;
         end loop;
      end;
      return True;
   end Is_Uniform;

   function Variables_Count (C : Cover) return Natural is
   begin
      if C.Is_Empty then
         return 0;
      else
         return C.First_Element'Length;
      end if;
   end Variables_Count;

   function Consistent (F, R : Cover) return Boolean is
   begin
      if F.Is_Empty or else R.Is_Empty then
         return True;
      end if;
      return Variables_Count (F) = Variables_Count (R);
   end Consistent;

   procedure Expand (F : in out Cover; R : in Cover) is
      Intersects : Boolean;
      Old_Val    : Logic_Value;
      Current    : Cube (1 .. Variables_Count (F));
   begin
      --  Explicit defensive checks throwing named exceptions for tests
      if not Is_Uniform (F) or else not Is_Uniform (R) then
         raise Invalid_Cover;
      end if;
      if not Consistent (F, R) then
         raise Inconsistent_Covers;
      end if;

      if F.Is_Empty then
         return;
      end if;

      for I in 1 .. Positive (F.Length) loop
         Current := F.Element (I);
         for V in Current'Range loop
            if Current (V) /= Dont_Care then
               Old_Val := Current (V);
               Current (V) := Dont_Care;
               Intersects := False;

               --  Check if this expansion causes an overlap with the OFF-set
               for X of R loop
                  if Overlaps (Current, X) then
                     Intersects := True;
                     exit;
                  end if;
               end loop;

               --  Revert if invalid
               if Intersects then
                  Current (V) := Old_Val;
               end if;
            end if;
         end loop;
         F.Replace_Element (I, Current);
      end loop;
   end Expand;

   procedure Irredundant (F : in out Cover) is
      I            : Positive := 1;
      J            : Positive;
      Is_Redundant : Boolean;
   begin
      if not Is_Uniform (F) then
         raise Invalid_Cover;
      end if;

      while I <= Positive (F.Length) loop
         Is_Redundant := False;
         J := 1;
         
         while J <= Positive (F.Length) loop
            if I /= J then
               if Subsumes (F.Element (J), F.Element (I)) then
                  --  Handle exact duplicates safely to avoid removing both
                  if Subsumes (F.Element (I), F.Element (J)) then
                     if J < I then
                        Is_Redundant := True;
                        exit;
                     end if;
                  else
                     Is_Redundant := True;
                     exit;
                  end if;
               end if;
            end if;
            J := J + 1;
         end loop;

         if Is_Redundant then
            --  Deleting shifts elements, so we do not increment I
            F.Delete (I);
         else
            I := I + 1;
         end if;
      end loop;
   end Irredundant;

   procedure Reduce (F : in out Cover) is
      Current, C0, C1 : Cube (1 .. Variables_Count (F));
      Reduced         : Boolean;
   begin
      if not Is_Uniform (F) then
         raise Invalid_Cover;
      end if;

      if F.Is_Empty then
         return;
      end if;

      for I in 1 .. Positive (F.Length) loop
         Current := F.Element (I);
         for V in Current'Range loop
            if Current (V) = Dont_Care then
               C0 := Current; C0 (V) := Zero;
               C1 := Current; C1 (V) := One;
               Reduced := False;

               --  If the 'One' half of this cube is covered by another cube,
               --  we only need to keep the 'Zero' half.
               for J in 1 .. Positive (F.Length) loop
                  if I /= J and then Subsumes (F.Element (J), C1) then
                     Current := C0;
                     Reduced := True;
                     exit;
                  end if;
               end loop;

               if not Reduced then
                  --  Vice versa for the 'Zero' half.
                  for J in 1 .. Positive (F.Length) loop
                     if I /= J and then Subsumes (F.Element (J), C0) then
                        Current := C1;
                        exit;
                     end if;
                  end loop;
               end if;
            end if;
         end loop;
         F.Replace_Element (I, Current);
      end loop;
   end Reduce;

   procedure Minimize_Single_Pass (F : in out Cover; R : in Cover) is
   begin
      if not F.Is_Empty then
         Expand (F, R);
         Irredundant (F);
      end if;
   end Minimize_Single_Pass;

   procedure Minimize_Iterative (F : in out Cover; R : in Cover) is
      Old_Size : Natural;
   begin
      if F.Is_Empty then
         return;
      end if;

      --  Initial baseline expansion
      Expand (F, R);
      Irredundant (F);

      --  Main Espresso loop: Reduce, Expand, Irredundant
      loop
         Old_Size := Natural (F.Length);
         Reduce (F);
         Expand (F, R);
         Irredundant (F);
         exit when Natural (F.Length) >= Old_Size;
      end loop;
   end Minimize_Iterative;

end Espresso;
