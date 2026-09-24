pragma Ada_2022;

package body Isomorphic_Strings with SPARK_Mode => On is
   function Same_Relation (Left : Text_Array; Right : Text_Array;
                           A : Index; B : Index) return Boolean is
   begin
      return (Left (A) = Left (B)) = (Right (A) = Right (B));
   end Same_Relation;

   function Are_Isomorphic (Left : Text_Array; Right : Text_Array)
     return Boolean is
   begin
      return Same_Relation (Left, Right, 1, 2)
        and then Same_Relation (Left, Right, 1, 3)
        and then Same_Relation (Left, Right, 1, 4)
        and then Same_Relation (Left, Right, 1, 5)
        and then Same_Relation (Left, Right, 1, 6)
        and then Same_Relation (Left, Right, 2, 3)
        and then Same_Relation (Left, Right, 2, 4)
        and then Same_Relation (Left, Right, 2, 5)
        and then Same_Relation (Left, Right, 2, 6)
        and then Same_Relation (Left, Right, 3, 4)
        and then Same_Relation (Left, Right, 3, 5)
        and then Same_Relation (Left, Right, 3, 6)
        and then Same_Relation (Left, Right, 4, 5)
        and then Same_Relation (Left, Right, 4, 6)
        and then Same_Relation (Left, Right, 5, 6);
   end Are_Isomorphic;
end Isomorphic_Strings;
