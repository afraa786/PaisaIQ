package com.alpharedge.service;

import com.alpharedge.dto.tax.TaxSummary;
import com.itextpdf.text.*;
import com.itextpdf.text.pdf.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

@Slf4j
@Service
public class TaxReportService {

    // ── Colours ───────────────────────────────────────────────────────────────
    private static final BaseColor DARK_BG      = new BaseColor(13, 17, 23);
    private static final BaseColor CARD_BG      = new BaseColor(22, 27, 34);
    private static final BaseColor ACCENT_GREEN = new BaseColor(0, 200, 150);
    private static final BaseColor ACCENT_RED   = new BaseColor(248, 81, 73);
    private static final BaseColor TEXT_WHITE   = BaseColor.WHITE;
    private static final BaseColor TEXT_GRAY    = new BaseColor(139, 148, 158);
    private static final BaseColor TABLE_HEADER = new BaseColor(33, 41, 54);
    private static final BaseColor TABLE_ROW_ALT= new BaseColor(18, 23, 30);

    // ── Fonts — loaded lazily so iText doesn't fail at class-load time ────────
    private Font h1()     { return new Font(Font.FontFamily.HELVETICA, 22, Font.BOLD,   TEXT_WHITE); }
    private Font h2()     { return new Font(Font.FontFamily.HELVETICA, 14, Font.BOLD,   TEXT_WHITE); }
    private Font body()   { return new Font(Font.FontFamily.HELVETICA, 10, Font.NORMAL, TEXT_WHITE); }
    private Font gray()   { return new Font(Font.FontFamily.HELVETICA,  9, Font.ITALIC, TEXT_GRAY);  }
    private Font bigNum() { return new Font(Font.FontFamily.HELVETICA, 20, Font.BOLD,   TEXT_WHITE); }
    private Font bigNumAccent(boolean positive) {
        return new Font(Font.FontFamily.HELVETICA, 26, Font.BOLD,
                positive ? ACCENT_GREEN : ACCENT_RED);
    }
    private Font mono()   { return new Font(Font.FontFamily.COURIER,    9, Font.NORMAL, TEXT_WHITE); }
    private Font tableH() { return new Font(Font.FontFamily.HELVETICA,  9, Font.BOLD,   TEXT_WHITE); }
    private Font tableC() { return new Font(Font.FontFamily.HELVETICA,  9, Font.NORMAL, TEXT_WHITE); }

    // ─────────────────────────────────────────────────────────────────────────

    public byte[] generateTaxReport(TaxSummary summary) {
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            Document doc = new Document(PageSize.A4, 40, 40, 50, 50);
            PdfWriter writer = PdfWriter.getInstance(doc, out);

            writer.setPageEvent(new PageBackground());
            doc.open();

            buildPage1(doc, summary);
            doc.newPage();
            buildPage2(doc, summary);
            doc.newPage();
            buildPage3(doc, summary);

            doc.close();
            return out.toByteArray();
        } catch (Exception ex) {
            log.error("Error generating tax PDF", ex);
            throw new RuntimeException("PDF generation failed: " + ex.getMessage(), ex);
        }
    }

    // ── PAGE 1 — Summary ─────────────────────────────────────────────────────

    private void buildPage1(Document doc, TaxSummary s) throws DocumentException {
        // Header
        Paragraph header = new Paragraph(
                "AlphaEdge — Indian Crypto Tax Report FY " + s.getFinancialYear(), h1());
        header.setAlignment(Element.ALIGN_CENTER);
        header.setSpacingAfter(6);
        doc.add(header);

        String date = LocalDate.now().format(DateTimeFormatter.ofPattern("dd MMM yyyy"));
        Paragraph sub = new Paragraph(
                "Generated on " + date + "  |  For reference only — consult a CA for filing",
                gray());
        sub.setAlignment(Element.ALIGN_CENTER);
        sub.setSpacingAfter(24);
        doc.add(sub);

        // Divider
        doc.add(divider());

        // 4 number boxes — top row: Profit/Loss | Tax Owed
        PdfPTable top = twoColTable();
        top.addCell(numberBox("Total Profit / Loss",
                inr(s.getNetProfitLossInr()),
                s.getNetProfitLossInr() != null && s.getNetProfitLossInr().signum() >= 0,
                bigNum()));
        top.addCell(numberBox("Tax Owed (30%)",
                inr(s.getTaxOwedInr()), false, bigNum()));
        top.setSpacingAfter(12);
        doc.add(top);

        // Bottom row: TDS Paid | Net Tax Still Due (largest)
        PdfPTable bot = twoColTable();
        bot.addCell(numberBox("TDS Already Paid (1%)",
                inr(s.getTdsPaidInr()), true, bigNum()));
        bot.addCell(numberBox("NET TAX STILL DUE",
                inr(s.getNetTaxDueInr()),
                false,
                bigNumAccent(false)));
        bot.setSpacingAfter(30);
        doc.add(bot);

        // Disclaimer
        doc.add(divider());
        Paragraph disc = new Paragraph(
                "DISCLAIMER: This report is generated from trade data entered by the user. "
                + "AlphaEdge is not a CA firm. Tax calculations are based on Section 115BBH "
                + "(flat 30% on VDA profits) and Section 194S (1% TDS). "
                + "Losses on Virtual Digital Assets cannot be set off against any other income. "
                + "Please verify all figures with a qualified Chartered Accountant before filing your ITR.",
                gray());
        disc.setAlignment(Element.ALIGN_JUSTIFIED);
        doc.add(disc);
    }

    // ── PAGE 2 — Per-coin table ───────────────────────────────────────────────

    private void buildPage2(Document doc, TaxSummary s) throws DocumentException {
        pageTitle(doc, "Per-Coin Breakdown — FY " + s.getFinancialYear());

        float[] widths = {2.5f, 1.8f, 1.8f, 2.2f, 2.2f, 2.2f};
        PdfPTable table = new PdfPTable(widths);
        table.setWidthPercentage(100);
        table.setSpacingBefore(16);

        String[] headers = {"Coin", "Units Bought", "Units Sold", "Profit / Loss (₹)", "Tax (₹)", "TDS (₹)"};
        for (String h : headers) {
            PdfPCell cell = new PdfPCell(new Phrase(h, tableH()));
            cell.setBackgroundColor(TABLE_HEADER);
            cell.setPadding(8);
            cell.setBorder(Rectangle.NO_BORDER);
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            table.addCell(cell);
        }

        boolean alt = false;
        for (TaxSummary.CoinTaxDetail coin : s.getPerCoinBreakdown()) {
            BaseColor rowBg = alt ? TABLE_ROW_ALT : CARD_BG;
            boolean positive = coin.getProfitLossInr() != null && coin.getProfitLossInr().signum() >= 0;
            BaseColor pnlColor = positive ? ACCENT_GREEN : ACCENT_RED;

            addCell(table, coin.getCoinSymbol(), tableH(), rowBg, Element.ALIGN_LEFT);
            addCell(table, fmt8(coin.getUnitsBought()), tableC(), rowBg, Element.ALIGN_RIGHT);
            addCell(table, fmt8(coin.getUnitsSold()),   tableC(), rowBg, Element.ALIGN_RIGHT);
            addCellColored(table, inr(coin.getProfitLossInr()), tableC(), rowBg, pnlColor);
            addCell(table, inr(coin.getTaxInr()),       tableC(), rowBg, Element.ALIGN_RIGHT);
            addCell(table, inr(coin.getTdsInr()),       tableC(), rowBg, Element.ALIGN_RIGHT);
            alt = !alt;
        }

        // Totals row
        addCell(table, "TOTAL", tableH(), TABLE_HEADER, Element.ALIGN_LEFT);
        addCell(table, "",      tableH(), TABLE_HEADER, Element.ALIGN_RIGHT);
        addCell(table, "",      tableH(), TABLE_HEADER, Element.ALIGN_RIGHT);
        boolean totalPositive = s.getNetProfitLossInr() != null && s.getNetProfitLossInr().signum() >= 0;
        addCellColored(table, inr(s.getNetProfitLossInr()), tableH(), TABLE_HEADER,
                totalPositive ? ACCENT_GREEN : ACCENT_RED);
        addCell(table, inr(s.getTaxOwedInr()),  tableH(), TABLE_HEADER, Element.ALIGN_RIGHT);
        addCell(table, inr(s.getTdsPaidInr()),  tableH(), TABLE_HEADER, Element.ALIGN_RIGHT);

        doc.add(table);

        Paragraph note = new Paragraph(
                "\nNote: Under Section 115BBH, losses from one VDA cannot offset profits from another. "
                + "Each coin's profit is taxed independently at 30%.", gray());
        note.setSpacingBefore(12);
        doc.add(note);
    }

    // ── PAGE 3 — Audit trail ─────────────────────────────────────────────────

    private void buildPage3(Document doc, TaxSummary s) throws DocumentException {
        pageTitle(doc, "Calculation Steps — How These Numbers Were Computed");

        Paragraph intro = new Paragraph(
                "FIFO (First In, First Out) method applied per coin per transaction. "
                + "All amounts in INR.", gray());
        intro.setSpacingAfter(16);
        doc.add(intro);

        com.itextpdf.text.List list = new com.itextpdf.text.List(
                com.itextpdf.text.List.ORDERED, 16);
        list.setListSymbol(new Chunk("", mono()));

        int i = 1;
        for (String step : s.getCalculationSteps()) {
            ListItem item = new ListItem(i + ".  " + step, mono());
            item.setSpacingAfter(3);
            list.add(item);
            i++;
        }
        doc.add(list);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private PdfPCell numberBox(String label, String value, boolean positive, Font valueFont) {
        PdfPTable inner = new PdfPTable(1);
        inner.setWidthPercentage(100);

        PdfPCell labelCell = new PdfPCell(new Phrase(label, gray()));
        labelCell.setBackgroundColor(CARD_BG);
        labelCell.setBorder(Rectangle.NO_BORDER);
        labelCell.setPaddingTop(14);
        labelCell.setPaddingLeft(14);
        labelCell.setPaddingRight(14);
        labelCell.setPaddingBottom(4);
        inner.addCell(labelCell);

        PdfPCell valCell = new PdfPCell(new Phrase(value, valueFont));
        valCell.setBackgroundColor(CARD_BG);
        valCell.setBorder(Rectangle.NO_BORDER);
        valCell.setPaddingLeft(14);
        valCell.setPaddingRight(14);
        valCell.setPaddingBottom(14);
        inner.addCell(valCell);

        PdfPCell outer = new PdfPCell(inner);
        outer.setBorder(Rectangle.BOX);
        outer.setBorderColor(ACCENT_GREEN);
        outer.setBorderWidth(1.5f);
        outer.setPadding(4);
        outer.setBackgroundColor(CARD_BG);
        return outer;
    }

    private PdfPTable twoColTable() throws DocumentException {
        PdfPTable t = new PdfPTable(2);
        t.setWidthPercentage(100);
        t.setWidths(new float[]{1f, 1f});
        t.setSpacingBefore(12);
        return t;
    }

    private void addCell(PdfPTable table, String text, Font font,
                         BaseColor bg, int align) {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setBackgroundColor(bg);
        cell.setPadding(7);
        cell.setBorder(Rectangle.NO_BORDER);
        cell.setHorizontalAlignment(align);
        table.addCell(cell);
    }

    private void addCellColored(PdfPTable table, String text, Font baseFont,
                                BaseColor bg, BaseColor textColor) {
        Font colored = new Font(baseFont.getFamily(), baseFont.getSize(),
                baseFont.getStyle(), textColor);
        PdfPCell cell = new PdfPCell(new Phrase(text, colored));
        cell.setBackgroundColor(bg);
        cell.setPadding(7);
        cell.setBorder(Rectangle.NO_BORDER);
        cell.setHorizontalAlignment(Element.ALIGN_RIGHT);
        table.addCell(cell);
    }

    private void pageTitle(Document doc, String title) throws DocumentException {
        Paragraph p = new Paragraph(title, h2());
        p.setSpacingAfter(4);
        doc.add(p);
        doc.add(divider());
    }

    private Paragraph divider() {
        Paragraph p = new Paragraph(" ");
        p.setSpacingBefore(2);
        p.setSpacingAfter(2);
        return p;
    }

    private static String inr(java.math.BigDecimal v) {
        if (v == null) return "₹0.00";
        NumberFormat fmt = NumberFormat.getCurrencyInstance(new Locale("en", "IN"));
        return fmt.format(v.doubleValue());
    }

    private static String fmt8(java.math.BigDecimal v) {
        if (v == null) return "0";
        return v.stripTrailingZeros().toPlainString();
    }

    // ── Dark background on every page ─────────────────────────────────────────

    private static class PageBackground extends PdfPageEventHelper {
        @Override
        public void onStartPage(PdfWriter writer, Document document) {
            PdfContentByte canvas = writer.getDirectContentUnder();
            Rectangle pageSize = document.getPageSize();
            canvas.setColorFill(DARK_BG);
            canvas.rectangle(0, 0, pageSize.getWidth(), pageSize.getHeight());
            canvas.fill();
        }
    }
}
