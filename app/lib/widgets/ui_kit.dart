import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          if (showBack) ...[
            Material(
              color: AppColors.card,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack ?? () => Navigator.maybePop(context),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.chevron_left, color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withAlpha(90),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.card,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final EdgeInsetsGeometry padding;

  const InfoCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.card,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class ListRowCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ListRowCard({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          trailing ?? const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;

  const StatTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class HeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const HeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const Pill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.darkGreen : AppColors.card,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PillTabs extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const PillTabs({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Pill(
              label: options[i],
              selected: i == selectedIndex,
              onTap: () => onChanged(i),
            ),
          ),
        ],
      ],
    );
  }
}

class PillScroller extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const PillScroller({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Pill(
          label: options[i],
          selected: i == selectedIndex,
          onTap: () => onChanged(i),
        ),
      ),
    );
  }
}

enum NoteType { success, info, warning, error }

class NoteBanner extends StatelessWidget {
  final String text;
  final NoteType type;

  const NoteBanner({super.key, required this.text, this.type = NoteType.info});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (type) {
      NoteType.success => (AppColors.successBg, AppColors.green),
      NoteType.info => (AppColors.peach, AppColors.primary),
      NoteType.warning => (AppColors.warningBg, AppColors.warningText),
      NoteType.error => (AppColors.peach, Theme.of(context).colorScheme.error),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: foreground)),
    );
  }
}

class SuccessCard extends StatelessWidget {
  final String title;
  final String message;

  const SuccessCard({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: AppColors.green, size: 20),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const LabeledField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          TextFormField(
            controller: controller,
            initialValue: initialValue,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            maxLength: maxLength,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const AmountRow(this.label, this.value, {super.key, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
        : const TextStyle(fontSize: 12, color: AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;

  const NavItem(this.icon, this.label);
}

const serverNavItems = [
  NavItem(Icons.home_outlined, 'Home'),
  NavItem(Icons.receipt_long_outlined, 'Orders'),
  NavItem(Icons.table_restaurant_outlined, 'Tables'),
  NavItem(Icons.logout, 'Sign out'),
];

const kitchenNavItems = [
  NavItem(Icons.soup_kitchen_outlined, 'Queue'),
  NavItem(Icons.check, 'Ready'),
  NavItem(Icons.logout, 'Sign out'),
];

const managerNavItems = [
  NavItem(Icons.home_outlined, 'Home'),
  NavItem(Icons.menu_book_outlined, 'Menu'),
  NavItem(Icons.bar_chart, 'Reports'),
  NavItem(Icons.settings_outlined, 'Settings'),
];

class RoleBottomNav extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const RoleBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].icon,
                          size: 22,
                          color: i == currentIndex ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            color: i == currentIndex ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
