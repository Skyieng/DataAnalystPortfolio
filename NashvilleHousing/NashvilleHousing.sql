USE Housing
SELECT * FROM dbo.NashvilleHousing

-- Standardized SaleDate Format
SELECT SaleDate, SaleDateStandardized
FROM dbo.NashvilleHousing

ALTER TABLE Housing.dbo.NashvilleHousing
ADD SaleDateStandardized Date;

UPDATE dbo.NashvilleHousing
SET SaleDateStandardized = CONVERT(date, SaleDate)

-- Populate Property Address Data
SELECT *
FROM Housing.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL


-- Split PropertyAddress
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1), SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) FROM Housing.dbo.NashvilleHousing

ALTER TABLE dbo.NashvilleHousing
ADD Address1 nvarchar(255)

UPDATE Housing.dbo.NashvilleHousing
SET Address1 = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)
FROM dbo.NashvilleHousing

ALTER TABLE Housing.dbo.NashvilleHousing
ADD Address2 nvarchar(255)

UPDATE dbo.NashvilleHousing
SET Address2 = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))
FROM dbo.NashvilleHousing

-- Rename column (PropertyAddress)
EXEC sp_rename 'dbo.NashvilleHousing.Address1', 'PropertyAddress1', 'COLUMN';
EXEC sp_rename 'dbo.NashvilleHousing.Address2', 'PropertyCity', 'COLUMN';

-- Drop column (PropertyAddress)
ALTER TABLE dbo.NashvilleHousing
DROP COLUMN Address2

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM 
	dbo.NashvilleHousing

-- Split OwnerAddress
ALTER TABLE Housing.dbo.NashvilleHousing
ADD OwnerAddress1 nvarchar(255)

ALTER TABLE Housing.dbo.NashvilleHousing
ADD OwnerCity nvarchar(255)

ALTER TABLE Housing.dbo.NashvilleHousing
ADD OwnerState nvarchar(255)

UPDATE Housing.dbo.NashvilleHousing
SET OwnerAddress1 = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE Housing.dbo.NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE Housing.dbo.NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Normalize SoldAsVacant column
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM dbo.NashvilleHousing
GROUP BY SoldAsVacant

SELECT 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM dbo.NashvilleHousing

UPDATE dbo.NashvilleHousing
SET SoldAsVacant = 	
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END

-- Remove duplicates in WITH table
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
					UniqueID
				) row_num
FROM dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

-- Remove unuse columns
ALTER TABLE dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


