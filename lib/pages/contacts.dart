import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/components/contact_widget.dart';
import 'package:flutter_setup/components/navigation_drawer.dart';

class Contacts extends StatelessWidget {
  const Contacts({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is ContactsErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      builder: (context, state) {
        // Base Scaffold with common AppBar
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: AppBar(
              iconTheme: IconThemeData(color: Colors.white),
              backgroundColor:
                  const Color.fromARGB(255, 0, 56, 147).withOpacity(0.9),
              elevation: 0,
              title: Text(
                'Suraksha',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: MediaQuery.of(context).size.height * 0.03,
                      letterSpacing: 1.2,
                    ),
              ),
              centerTitle: false,
            ),
          ),
          drawer: Navigation_Drawer(select: 3),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state is ContactsLoadingState) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color.fromARGB(255, 0, 56, 147).withOpacity(0.8),
        ),
      );
    }

    if (state is ContactsFetchedState) {
      if (state.contacts.isEmpty) {
        return const Center(
          child: Text('No contacts found'),
        );
      }

      return Container(
        color: Colors.white,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.contacts.length,
          itemBuilder: (context, index) {
            return ContactWidget(
              contact: state.contacts[index],
              onAdd: () {
                // Handle add contact
              },
              onRemove: () {
                // Handle remove contact
              },
            );
          },
        ),
      );
    }

    if (state is ContactsErrorState) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading contacts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                context.read<HomeBloc>().add(ShowContactsEvent());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return const Center(
      child: Text('Please load contacts'),
    );
  }
}
