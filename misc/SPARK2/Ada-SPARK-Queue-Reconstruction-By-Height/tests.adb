with Queue_Reconstruction_By_Height;
procedure Tests is
begin
   pragma Assert
     (Queue_Reconstruction_By_Height.Insert_Position (8, 0) = 0);
   pragma Assert
     (Queue_Reconstruction_By_Height.Insert_Position (8, 3) = 3);
   pragma Assert
     (Queue_Reconstruction_By_Height.Insert_Position (8, 8) = 8);
end Tests;
