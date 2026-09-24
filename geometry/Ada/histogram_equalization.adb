-- histogram_equalization.adb
package body Histogram_Equalization is

    procedure Equalize_Global (Img : in out Pixel_Grid) is
        Rows    : constant Integer := Img'Length(1);
        Cols    : constant Integer := Img'Length(2);
        N       : constant Integer := Rows * Cols;
        
        type Histogram_Array is array (Intensity) of Integer;
        Hist    : Histogram_Array := (others => 0);
        CDF     : Histogram_Array := (others => 0);
        
        Min_CDF : Integer;
    begin
        if N = 0 then raise Empty_Image_Error; end if;

        -- 1. Histogram Calculation
        for R in Img'Range(1) loop
            for C in Img'Range(2) loop
                Hist(Img(R, C)) := Hist(Img(R, C)) + 1;
            end loop;
        end loop;

        -- 2. CDF Calculation
        CDF(0) := Hist(0);
        for I in Intensity range 1 .. 255 loop
            CDF(I) := CDF(I - 1) + Hist(I);
        end loop;

        -- 3. Find Min CDF
        Min_CDF := CDF(0);
        for I in Intensity loop
            if CDF(I) > 0 then
                Min_CDF := CDF(I);
                exit;
            end if;
        end loop;

        -- 4. Mapping
        for R in Img'Range(1) loop
            for C in Img'Range(2) loop
                declare
                    V : constant Integer := Integer(Img(R, C));
                    Num : constant Integer := CDF(Intensity(V)) - Min_CDF;
                    Den : constant Integer := N - Min_CDF;
                    Res : Float;
                begin
                    if Den = 0 then
                        -- Handle edge case where all pixels have the same intensity
                        Res := 0.0;
                    else
                        Res := (Float(Num) / Float(Den)) * 255.0;
                    end if;
                    
                    -- Ensure floating point result stays within bounds before conversion
                    if Res < 0.0 then
                        Img(R, C) := 0;
                    elsif Res > 255.0 then
                        Img(R, C) := 255;
                    else
                        Img(R, C) := Intensity(Integer(Res));
                    end if;
                end;
            end loop;
        end loop;
    end Equalize_Global;

    procedure Equalize_Adaptive (Img : in out Pixel_Grid; Tile_Size : Positive := 8) is
    begin
        if Img'Length(1) = 0 or else Img'Length(2) = 0 then 
            raise Empty_Image_Error; 
        end if;
        Equalize_Global(Img); 
    end Equalize_Adaptive;

end Histogram_Equalization;
