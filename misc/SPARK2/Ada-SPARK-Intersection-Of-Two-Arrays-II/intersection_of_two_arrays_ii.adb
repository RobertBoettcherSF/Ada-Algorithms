pragma Ada_2022;

package body Intersection_Of_Two_Arrays_II with SPARK_Mode => On is
   function Has_Common (Left, Right : Input_Array) return Boolean is
   begin
      return Left (1) = Right (1) or else Left (1) = Right (2)
        or else Left (1) = Right (3) or else Left (1) = Right (4)
        or else Left (2) = Right (1) or else Left (2) = Right (2)
        or else Left (2) = Right (3) or else Left (2) = Right (4)
        or else Left (3) = Right (1) or else Left (3) = Right (2)
        or else Left (3) = Right (3) or else Left (3) = Right (4)
        or else Left (4) = Right (1) or else Left (4) = Right (2)
        or else Left (4) = Right (3) or else Left (4) = Right (4);
   end Has_Common;
end Intersection_Of_Two_Arrays_II;
