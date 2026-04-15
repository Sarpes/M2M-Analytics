USE northwinddb
GO

-- SORU 1: En Yüksek Gelir Getiren 5 Ürünü ve Alternatif Tedarikçi Önerileri
-- Toplam satış gelirine göre en yüksek geliri sağlayan ilk 5 ürünü bulunuz.

-- (UnitPrice * Quantity) * (1 - Discount) kullanarak toplam geliri hesaplayınız.
-- Bu ürünlerin hangi tedarikçilerden alındığını analiz edin
-- Alternatif tedarikçilerin sunduğu fiyatlarla karşılaştırma yapın

-- Database'de bir ürün icin sadece bir tedarikci tanimlanmis, fiyat karsılastırılması yapılamaz. o yüzden alternatif tedarikci önerileri kategori bazında yapildi.


SELECT DISTINCT T.Ürün_Adi, T.Kategori_Adi, T.Birim_Fiyat, T.Toplam_Gelir, T.Tedarikci_Adi Mevcut_Tedarikci, AltS.CompanyName Alternatif_Tedarikci

    -- Alt ile baslayan tablolar northwind database products ve suppliers (ürün ismi + birim fiyat productstan, tedarikci ismi supplierstan) tablo aliasları.
FROM

    (SELECT  TOP 5 p.ProductID Ürün_ID, p.ProductName Ürün_Adi, p.CategoryID Kategori_ID, p.SupplierID Tedarikci_ID, s.CompanyName Tedarikci_Adi, p.UnitPrice Birim_Fiyat,c.CategoryName Kategori_Adi,
        ROUND(SUM((od.UnitPrice*od.Quantity)*(1-od.Discount)),2) Toplam_Gelir
    FROM OrderDetails od 
    LEFT JOIN Products p ON od.ProductID=p.ProductID
    LEFT JOIN Categories c ON p.CategoryID=c.CategoryID
    LEFT JOIN Suppliers s ON p.SupplierID=s.SupplierID
    GROUP by p.ProductID, p.ProductName, p.CategoryID,c.CategoryName, p.SupplierID, s.CompanyName, p.UnitPrice
    ORDER BY Toplam_Gelir DESC
    ) T -- Top 5 ürünü veren sub query

LEFT JOIN Products AltP ON T.Kategori_ID=AltP.CategoryID -- aynı kategoriye ait alternatif ürünler vü
LEFT JOIN Suppliers AltS ON AltP.SupplierID = AltS.SupplierID -- alternatif ürünlerin tedarikcisi

WHERE T.Tedarikci_ID <> AltP.SupplierID -- ürünün mevcut tedarikcisini tekrardan sonuc tablosuna alternatif oalrak getirmemek icin
ORDER BY T.Toplam_Gelir DESC;


-- SORU 2: 1997 ve 1998'de En Çok Satış Yapan İlk 5 Çalışanı Karşılaştırın ve 1999 İçin Tahmini Performans Senaryosu Oluşturun

-- 1997 ve 1998 yıllarında en fazla satış yapan ilk 5 çalışanı bulun
-- İki yıl üst üste listede olan çalışanları belirleyin. 
-- Her çalışanın yıllık satış artış oranını hesaplayın. 
-- Eğer çalışanlar aynı oranda performanslarını artırmaya devam ederse, 1999 yılında ne kadar satış yapacaklarını tahmin edin. 

SELECT  -- Satis degisim orani ve 1999 tahmini
    A.Calisan_ID, A.Adi_Soyadi, A.Toplam_Satis_1997, A.Sira_1997, A.Toplam_Satis_1998, A.Sira_1998,
    CASE WHEN A.Toplam_Satis_1998 IS NOT NULL AND A.Toplam_Satis_1997 IS NOT NULL AND A.Toplam_Satis_1997 <> 0 -- bölme isleminde 0 veya null gelmemesi icin
    THEN ROUND((((A.Toplam_Satis_1998-A.Toplam_Satis_1997)/(A.Toplam_Satis_1997))*100),2) END Degisim_Orani,  
    CASE WHEN A.Toplam_Satis_1998 IS NOT NULL AND A.Toplam_Satis_1997 IS NOT NULL AND A.Toplam_Satis_1997 <> 0 -- bölme isleminde 0 veya null gelmemesi icin
    THEN ROUND(((A.Toplam_Satis_1998)*(1+((A.Toplam_Satis_1998-A.Toplam_Satis_1997)/(A.Toplam_Satis_1997)))),2) END Tahmin_1999
FROM 
    (SELECT
        T.Calisan_ID, T.Adi_Soyadi, -- calisanlarin performansini veren sub querydeki (T) satirlari sutun yapmak icin max + case (conditional aggregation, sayisal degerler oldugu icin max kullandım)
        MAX(CASE WHEN T.Yil = 1997 THEN T.Toplam_Satis END) Toplam_Satis_1997,
        MAX(CASE WHEN T.Yil = 1997 THEN T.RN END) Sira_1997,
        MAX(CASE WHEN T.Yil = 1998 THEN T.Toplam_Satis END) Toplam_Satis_1998,
        MAX(CASE WHEN T.Yil = 1998 THEN T.RN END) Sira_1998 
    FROM

        (SELECT e.EmployeeID Calisan_ID, e.FirstName+' '+e.LastName Adi_Soyadi, YEAR(o.OrderDate) Yil, 
            ROUND( CASE  WHEN YEAR(o.OrderDate) = 1998  THEN SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) * (12.0 / 5.0) ELSE SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) END, 2) Toplam_Satis,
            ROW_NUMBER() OVER (PARTITION BY YEAR(o.OrderDate) ORDER BY 
            ROUND( CASE  WHEN YEAR(o.OrderDate) = 1998  THEN SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) * (12.0 / 5.0) ELSE SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) END, 2) DESC) RN
            FROM Employees e
            LEFT JOIN Orders o ON e.EmployeeID=o.EmployeeID
            LEFT JOIN OrderDetails od ON o.OrderID=od.ORderID
            WHERE YEAR(o.OrderDate) IN (1997,1998) 
            GROUP BY e.EmployeeID, e.FirstName+' '+e.LastName, YEAR(o.OrderDate)
        ) T  -- tüm calisanların performansini veren sub query
    
    GROUP BY T.Calisan_ID, T.Adi_Soyadi
    HAVING MAX(CASE WHEN T.Yil = 1997 THEN T.RN END) <= 5 AND MAX(CASE WHEN T.Yil = 1998 THEN T.RN END) <= 5  -- hem 1997 de hem de 1998 de top5 icinde olan calısanları filtrelemek icin
    ) A

ORDER BY Tahmin_1999 DESC;  

-- SORU 3: En Yüksek Satış Geliri Sağlayan 5 Müşteriyi Bulun ve Özel Kampanya Stratejisi Sunun 

-- Son iki yılın toplam satış gelirine göre en fazla kazanç sağlayan ilk 5 müşteriyi belirleyiniz.
-- Müşteri adı, toplam sipariş tutarı ve sipariş sayısı listelenmelidir.
-- Bu müşterilerin sipariş alışkanlıklarını analiz edin.

-- Son iki yıl 06.05.1998 - 06.05.1996,  Analiz Tarihi = 01.06.1998

SELECT TOP 5 o.CustomerID Müsteri_ID, c.CompanyName Müsteri_Adi, 
        DATEDIFF(DAY,MIN(OrderDate),'1998-06-01') Tenure, 
        DATEDIFF(DAY,MAX(OrderDate),'1998-06-01') Recency,
        COUNT(DISTINCT o.ORderID) Frequency, 
        ROUND(SUM((od.UnitPrice*od.Quantity)*(1-od.Discount)),2) Monetary,
        CASE WHEN COUNT(DISTINCT o.OrderID) IS NOT NULL AND COUNT(DISTINCT o.OrderID) <> 0 -- bölme isleminde 0 veya null gelmemesi icin
        THEN ROUND((ROUND(SUM((od.UnitPrice*od.Quantity)*(1-od.Discount)),2)/COUNT(DISTINCT o.OrderID)),2)
        END Avg_Basket_Size
FROM Orders o

LEFT JOIN OrderDetails od ON o.ORderID=od.OrderID
LEFT JOIN Customers c ON o.CustomerID=c.CustomerID
WHERE o.OrderDate BETWEEN '1996-05-06' AND '1998-05-06'
GROUP BY o.CustomerID,c.CompanyName
ORDER BY Monetary DESC;


Select p.ProductID

FROM OrderDetails od 
LEFT JOIN Products p ON od.ProductID=p.ProductID

WHERE p.ProductID IS NULL